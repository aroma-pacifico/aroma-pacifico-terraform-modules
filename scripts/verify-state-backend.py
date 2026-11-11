"""Inspect mocked graphs and exercise policy decisions offline; never call AWS."""
from collections import Counter
from fnmatch import fnmatchcase
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
MODULE = ROOT / 'modules/state-backend'
EXPECTED = {'aws_kms_key', 'aws_kms_alias', 'aws_s3_bucket', 'aws_s3_bucket_ownership_controls',
            'aws_s3_bucket_public_access_block', 'aws_s3_bucket_versioning',
            'aws_s3_bucket_server_side_encryption_configuration', 'aws_s3_bucket_policy'}

def require(condition, message):
    if not condition:
        raise RuntimeError(message)

def sequence(value):
    return value if isinstance(value, list) else [value]

def decision(policy, principal, action, resource, context):
    """Evaluator for these policy operators only, not a replacement for AWS IAM."""
    context = dict(context, **{'aws:PrincipalArn': principal})
    allowed = False
    for statement in policy['Statement']:
        principals = statement['Principal']
        principals = principals['AWS'] if isinstance(principals, dict) else principals
        if not any(fnmatchcase(principal, p) for p in sequence(principals)):
            continue
        if not any(fnmatchcase(action.lower(), a.lower()) for a in sequence(statement['Action'])):
            continue
        if not any(fnmatchcase(resource, r) for r in sequence(statement['Resource'])):
            continue
        matches = True
        for operator, conditions in statement.get('Condition', {}).items():
            for key, expected in conditions.items():
                value = context.get(key)
                values = [str(v).lower() if isinstance(v, bool) else str(v) for v in sequence(expected)]
                if operator == 'Null':
                    match = str(value is None).lower() in values
                elif operator == 'Bool':
                    match = value is not None and str(value).lower() in values
                elif operator in {'StringEquals', 'ArnEquals'}:
                    match = value is not None and str(value) in values
                elif operator in {'StringNotEquals', 'ArnNotEquals'}:
                    match = value is None or str(value) not in values
                else:
                    raise RuntimeError('Unreviewed policy operator: ' + operator)
                matches = matches and match
        if not matches:
            continue
        if statement['Effect'] == 'Deny':
            return 'explicit_deny'
        allowed = True
    return 'allow' if allowed else 'implicit_deny'

for path in MODULE.rglob('*.tftest.hcl'):
    commands = re.findall(r'command\s*=\s*(\w+)', path.read_text(encoding='utf-8'))
    require(commands and set(commands) == {'plan'} and 'mock_provider "aws"' in path.read_text(), str(path))
source = (MODULE / 'main.tf').read_text(encoding='utf-8')
require(source.count('prevent_destroy = true') == 2, 'Bucket/key deletion safeguards missing')
require('aws_s3_bucket_acl' not in source and 'aws_s3_bucket_lifecycle_configuration' not in source,
        'Unexpected ACL or state-expiry resource')
require(not re.search(r'\b(provider|backend)\s+"', '\n'.join(p.read_text() for p in MODULE.glob('*.tf') if p.name != 'versions.tf')),
        'Child configures a provider/backend')

result = subprocess.run(['terraform', f'-chdir={MODULE}', 'test', '-json', '-verbose', '-no-color'],
                        capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=120)
require(result.returncode == 0, result.stdout + result.stderr)
events = [json.loads(line) for line in result.stdout.splitlines()]
summary = next(e['test_summary'] for e in events if e.get('type') == 'test_summary')
require(summary['passed'] == 18 and summary['failed'] == 0, str(summary))
plans = {e['@testrun']: e['test_plan'] for e in events if e.get('type') == 'test_plan'}
for name in ['qa_backend', 'dev_backend', 'pdn_backend', 'plan_only_domain']:
    changes = plans[name]['resource_changes']
    require(Counter(c['type'] for c in changes) == Counter({t: 1 for t in EXPECTED}), name)
    require(all(c['change']['actions'] == ['create'] for c in changes), name)
    print(f'PASS {name}: one environment, eight mocked creates, zero destroys/replacements')

resources = {c['type']: c['change']['after'] for c in plans['qa_backend']['resource_changes']}
bucket_policy = json.loads(resources['aws_s3_bucket_policy']['policy'])
key_policy = json.loads(resources['aws_kms_key']['policy'])
account = format(0, '012d')
role = lambda suffix: f'arn:aws:iam::{account}:role/fixture-{suffix}'
bucket = 'arn:aws:s3:::fx-cf-qa-state'
state = bucket + '/network/terraform.tfstate'
lock = state + '.tflock'
tls = {'aws:SecureTransport': True}
checks = [
    ('plan reads own state', 'network-plan', 's3:GetObject', state, tls, 'allow'),
    ('plan cannot write state', 'network-plan', 's3:PutObject', state, tls, 'explicit_deny'),
    ('plan writes own lock', 'network-plan', 's3:PutObject', lock, tls, 'allow'),
    ('plan releases own lock', 'network-plan', 's3:DeleteObject', lock, tls, 'allow'),
    ('cross-domain read denied', 'network-plan', 's3:GetObject', bucket + '/security/terraform.tfstate', tls, 'explicit_deny'),
    ('cross-domain lock denied', 'network-plan', 's3:PutObject', bucket + '/security/terraform.tfstate.tflock', tls, 'explicit_deny'),
    ('writer writes own state', 'network-writer', 's3:PutObject', state, tls, 'allow'),
    ('writer cannot delete state', 'network-writer', 's3:DeleteObject', state, tls, 'explicit_deny'),
    ('writer cannot delete a version', 'network-writer', 's3:DeleteObjectVersion', state, tls, 'explicit_deny'),
    ('non-TLS rejected', 'network-plan', 's3:GetObject', state, {'aws:SecureTransport': False}, 'explicit_deny'),
    ('unknown role rejected', 'unknown', 's3:GetObject', state, tls, 'explicit_deny'),
    ('wrong encryption rejected', 'network-writer', 's3:PutObject', state, dict(tls, **{'s3:x-amz-server-side-encryption': 'AES256'}), 'explicit_deny'),
    ('KMS without key rejected', 'network-writer', 's3:PutObject', state, dict(tls, **{'s3:x-amz-server-side-encryption': 'aws:kms'}), 'explicit_deny'),
    ('wrong CMK rejected', 'network-writer', 's3:PutObject', state, dict(tls, **{'s3:x-amz-server-side-encryption-aws-kms-key-id': 'wrong-key'}), 'explicit_deny'),
    ('approved explicit CMK accepted', 'network-writer', 's3:PutObject', state, dict(tls, **{'s3:x-amz-server-side-encryption': 'aws:kms', 's3:x-amz-server-side-encryption-aws-kms-key-id': resources['aws_kms_key']['arn']}), 'allow'),
    ('plan lists own prefix', 'network-plan', 's3:ListBucket', bucket, dict(tls, **{'s3:prefix': 'network/'}), 'allow'),
    ('other prefix has no grant', 'network-plan', 's3:ListBucket', bucket, dict(tls, **{'s3:prefix': 'security/'}), 'implicit_deny'),
]
for label, principal, action, resource, context, expected in checks:
    require(decision(bucket_policy, role(principal), action, resource, context) == expected, label)
    print('PASS policy: ' + label)
key_context = {'kms:CallerAccount': account, 'kms:ViaService': 's3.us-east-1.amazonaws.com',
               'kms:EncryptionContext:aws:s3:arn': state}
key_checks = [
    ('plan decrypts S3 state', 'network-plan', 'kms:Decrypt', key_context, 'allow'),
    ('plan encrypts S3 lock', 'network-plan', 'kms:GenerateDataKey', dict(key_context, **{'kms:EncryptionContext:aws:s3:arn': lock}), 'allow'),
    ('direct decrypt has no grant', 'network-plan', 'kms:Decrypt', {}, 'implicit_deny'),
    ('cross-domain KMS context has no grant', 'network-plan', 'kms:Decrypt', dict(key_context, **{'kms:EncryptionContext:aws:s3:arn': bucket + '/security/terraform.tfstate'}), 'implicit_deny'),
    ('unknown KMS principal has no grant', 'unknown', 'kms:Decrypt', key_context, 'implicit_deny'),
    ('auditor reads policy', 'auditor', 'kms:GetKeyPolicy', {}, 'allow'),
    ('auditor cannot change policy', 'auditor', 'kms:PutKeyPolicy', {}, 'implicit_deny'),
    ('administrator cannot decrypt by default', 'admin', 'kms:Decrypt', key_context, 'implicit_deny'),
    ('administrator changes policy', 'admin', 'kms:PutKeyPolicy', {}, 'allow'),
    ('administrator has no deletion grant', 'admin', 'kms:ScheduleKeyDeletion', {}, 'implicit_deny'),
]
for label, principal, action, context, expected in key_checks:
    require(decision(key_policy, role(principal), action, '*', context) == expected, label)
    print('PASS policy: ' + label)
require(all(s['Effect'] == 'Deny' or s['Principal'] != '*' for s in bucket_policy['Statement']), 'Wildcard Allow principal')
require(not list(MODULE.rglob('*.tfstate*')), 'Unexpected state files')
print(f'PASS {summary["passed"]} native scenarios and {len(checks) + len(key_checks)} policy decisions')
print('LIMIT: simplified policy evaluation and mocks do not establish AWS IAM/backend behavior')
