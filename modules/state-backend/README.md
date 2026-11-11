# State backend resource module

Refs aroma-pacifico/aroma-pacifico-roadmap#22. IMPLEMENTED; VERIFIED OFFLINE only.
One invocation manages one environment's state bucket and customer-managed key.
ADR-003 and ASM-213 assign this graph to B02. It creates no IAM roles, network,
application resources, credentials, lock table or environment deployment loop.

## Resources and controls

| Resource | Purpose |
|---|---|
| aws_kms_key.state | State/lock encryption; 365-day rotation, 30-day deletion window, lockout check retained, prevent_destroy |
| aws_kms_alias.state | Stable alias using the root-built name |
| aws_s3_bucket.state | One bucket, force_destroy=false, prevent_destroy, explicit Name and supplied metadata |
| aws_s3_bucket_ownership_controls.state | BucketOwnerEnforced; no ACL resource |
| aws_s3_bucket_public_access_block.state | All four public-access controls enabled |
| aws_s3_bucket_versioning.state | Versioning enabled; no state expiry rules |
| aws_s3_bucket_server_side_encryption_configuration.state | SSE-KMS using this environment key; Bucket Keys disabled to retain object-level encryption context |
| aws_s3_bucket_policy.state | TLS enforcement, trusted-role boundary, exact domain state/lock grants and mutation restrictions |

## Inputs and outputs

| Input | Contract |
|---|---|
| client, project, environment | Root governance, one dev/qa/pdn environment |
| name_prefix | Root-built globally unique bucket name, matching governance, at most 28 characters |
| aws_context | Verified account_id, partition and region; supplied metadata is not account authentication |
| key_administrators | Explicit same-account IAM role ARNs; no root/session/wildcard principals |
| configuration_readers | Separate same-account read-only configuration roles for plan/review |
| domain_access | Map of domain to nonempty plan_role_arns and optional write_role_arns; empty writer set denies all state writes |
| additional_tags | Matching Client/Project/Environment plus Owner/CostCenter, supplied by root; Name cannot be overridden |

Plan and write identities are disjoint across domains. Key administration is
separate from state data access. Actual roles and IAM identity policies belong
to B06; this module does not fabricate them. The root must constrain the injected
provider account/Region. Only that provider can establish the real account.

Outputs are state_bucket_name, state_bucket_arn, state_kms_key_arn,
state_kms_key_id and backend_region. No policies, whole resources, secret values
or key material are outputs. Resource metadata still resides in Terraform state.

## Access model

Plan roles read their exact state object and read/write/delete its adjacent
terraform.tfstate.tflock. They cannot write state, read another configured
domain's state or manipulate its lock. Writer roles may additionally PutObject
on their own state. DeleteObject/DeleteObjectVersion of state is denied even
to writers; old versions have no automatic expiry. Domain ListBucket grants
are limited to named prefixes; actual Terraform S3 request compatibility still
REQUIRES AWS verification. B06 identity policies must remain equally narrow;
resource-policy implicit denial alone does not override an identity Allow.

Non-TLS and untrusted-principal requests are explicitly denied. Requests with
no encryption headers use mandatory bucket-default SSE-KMS. Explicit algorithms
other than aws:kms, explicit wrong keys, or explicit aws:kms without its key
reference are denied. Public access blocking and disabled ACLs are independent
controls, not substitutes for this policy.

KMS administration uses explicit roles/actions, with no default root delegation,
wildcard administrators, data decrypt grant, disable-key or deletion grant.
Configuration readers get metadata-read actions only. Data-key/encryption/decryption
grants require this account, S3 in the configured Region, and the exact domain
state/lock ARN as encryption context. KMS Resource="*" means the key whose policy
contains the statement; it is not an IAM grant on every key. S3 wildcard principals
and actions appear only in restrictive Deny statements, never broad Allow grants.

The eventual key creator must be covered by the approved administrator policy;
lockout safety is not bypassed. Alias management additionally needs appropriate
IAM permissions from B06. Administrators can change policies, so out-of-band
controls and independent review remain necessary. prevent_destroy protects
Terraform while the declaration is present; it does not protect a removed block
or an authorized console/API mutation. Recovery/version access requires a
separately reviewed operator procedure; the module grants no broad recovery role.

## Bootstrap and release boundary

The sample is an offline development root without an S3 backend. Its native
tests mock providers, plan one graph and return future backend configuration
for network/security/workload/state-backend. It does not initialize its own
not-yet-created bucket, create shared local state, apply or migrate anything.
The checked-in tfvars is deliberately incomplete; tests inject computed,
synthetic identities. Never use fixture identities or the sample for deployment.

Production root wiring is BLOCKED BY DEPENDENCY: B01/B03/B06 interfaces, a real
reviewed SemVer release and the approved bootstrap execution/evidence procedure
(PD-019). No release is asserted. PC-IAC-015 permits source="../" for this local
development sample only. A shared root must consume an actual reviewed tag.
Live bootstrap and state migration REQUIRE APPROVAL and remain prohibited here.

## Verification and layout

Use Terraform >=1.14; child AWS >=6.0.0; sample pins ~>6.0.0 with a root-only
6.0.0 lock. The child injects aws.project and has no provider/backend blocks.
Validate through sample/, which injects aws.principal. Direct child-as-root
validate lacks that alias and is not the intended composition.

Initialize child/sample with backend=false, then run terraform fmt -check -recursive,
sample validate, child/sample terraform test and python scripts/verify-state-backend.py.
Every native scenario is plan-mode and uses mock providers. The verifier checks
exact eight-resource graphs, static deletion guards and 27 policy decisions using
a deliberately limited evaluator. These are not real AWS plans or IAM proofs.
Private plan artifacts and state must not be committed. No AWS credential is
required for these checks; the public repository must never receive credentials.

```text
modules/state-backend/
|-- .gitignore, CHANGELOG.md, README.md
|-- data.tf, locals.tf, main.tf, outputs.tf, providers.tf, variables.tf, versions.tf
|-- sample/ (mock-only root, root lock, deliberately incomplete tfvars)
`-- tests/backend_unit_test.tftest.hcl
scripts/verify-state-backend.py
```

No bucket access-log destination or audit infrastructure is invented. B01/B06
and the platform owner must integrate the approved audit controls. There is no
replication, retention expiry or new bucket/KMS provisioning evidence. A code
revert is the current rollback; it cannot restore, migrate or remove live state.
