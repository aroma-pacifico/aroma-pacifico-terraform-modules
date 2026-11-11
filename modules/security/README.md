# Security module (box D06)

Reference module for the security baseline of one environment of the Aroma Pacifico pilot, built from the security and identity design of the architecture repository (A09). It creates the customer-managed keys, the two Cognito user pools with one group per role, the role of the revocation function and, on request, the bucket policy statements that force encrypted transport.

The module declares no provider block; the consuming root supplies the `aws.project` alias. Every value comes from the root, with no environment defaults, so one module serves `dev`, `qa` and `pdn`. The values in `sample/` are synthetic because this repository is public.

## What it builds

| Part | Resources | Design reference |
|---|---|---|
| Encryption at rest | Eight KMS keys, one per data class (`telemetry`, `objects`, `records`, `personal`, `logs`, `state`, `public_view`, `restricted`), each with an alias, automatic rotation every 365 days and a 30 day deletion window | Section 7.2 and 7.3, ASM-097 |
| Key policies | Explicit administrators, optional explicit users per class, and a deny of `kms:ScheduleKeyDeletion` and `kms:DisableKey` to everyone except the break-glass patterns | Section 7.3 |
| Identity directory | Staff user pool (MFA `ON`, TOTP only) and field user pool (MFA `OFF`, passwordless one-time codes) on the Essentials tier, both closed to self sign-up | Section 3, ASM-090, ASM-091 |
| Roles | Seven Cognito groups: `farmer`, `transporter`, `buyer` in the field pool and `collection_center_operator`, `drone_operator`, `agronomist`, `platform_operator` in the staff pool | Section 4.1 |
| Revocation | An IAM role that revokes a device certificate, detaches its policy and principal, marks the thing, and disables, signs out or regroups a user | Section 10 |
| Encryption in transit | Bucket policy denying plain HTTP and TLS older than 1.2, rendered for the buckets given in `protected_bucket_arns` | Section 7.1 |

## Contract

| Input | Type | Meaning |
|---|---|---|
| `client`, `project`, `environment` | `string` | Governance values; `environment` is `dev`, `qa` or `pdn`. |
| `name_prefix` | `string` | Prefix of every physical name, at most 16 characters. |
| `additional_tags` | `map(string)` | Extra tags merged into every taggable resource. |
| `key_administrator_arns` | `list(string)` | Explicit principals that administer the keys, normally the apply role of the security stack. At least one, no wildcard. |
| `key_user_arns` | `map(list(string))` | Explicit principals allowed to use each key, keyed by data class. A class without users gets none; keep `restricted` empty (ASM-165). |
| `break_glass_role_arn_patterns` | `list(string)` | ARN patterns of the only principals that may schedule deletion of a key or disable it. At least one. |
| `field_sms_configuration` | `object`, sensitive | SNS role and external ID for SMS codes of the field pool. Null leaves email codes only. |
| `protected_bucket_arns` | `set(string)` | Bucket ARNs for which the secure transport policy is rendered. Empty renders nothing. |

| Output | Meaning |
|---|---|
| `kms_key_arns`, `kms_key_ids`, `kms_key_alias_names` | Keys keyed by data class. Consumers such as the function pattern of B10 grant their roles the key of the data they handle. |
| `staff_user_pool_id`, `staff_user_pool_arn`, `field_user_pool_id`, `field_user_pool_arn` | Identifiers of the two pools. |
| `cognito_group_names` | Group name of each role. |
| `mfa_required_roles` | Roles in the pool that requires TOTP. |
| `revocation_role_arn`, `revocation_role_name` | Role of the revocation function. |
| `secure_transport_policy_statements_json` | Policy document with the two deny statements, or null. |

## Acceptance criteria

| Criterion | How the module meets it |
|---|---|
| The 6 roles of the architecture | The six roles of the case statement (farmer, transporter, collection-center operator, read-only buyer, drone operator, platform operator) are Cognito groups. The agronomist of ADR-002 is a seventh. The anonymous public reader has no identity by design (ASM-058). |
| MFA for the 3 mandatory roles | The staff pool sets `mfa_configuration = "ON"` with a software token. The collection-center operator, the drone operator and the platform operator live there, as does the agronomist. A staff user cannot sign in without a second factor because the pool refuses it. |
| Encryption at rest and secure connections | Every data class has its own rotated customer-managed key. Cognito encrypts its pools with AWS-managed keys, because it offers no customer-managed option (section 7.2). The secure transport policy covers S3. |
| Identity revocation for a farm node or a lost drone | The revocation role holds exactly the actions of section 10: `iot:UpdateCertificate` (to `REVOKED`), `iot:DetachPolicy`, `iot:DetachThingPrincipal` and `iot:UpdateThing`, plus the Cognito administrative actions for pilots and phones. The certificate is never deleted, for the audit trail. The function that calls them belongs to the platform; the 4 hour revocation target of ASM-098 is a target, not a measurement. |

## Decisions and limits

| Topic | Detail |
|---|---|
| Key policy without account root (ASM-270) | The policies name explicit administrators and users instead of delegating to the account root, as section 7.3 requires. The administrator list must therefore include the principal that applies the stack, or the key policy lock-out check refuses the key. The service roles that use the keys are created by other stacks, so the root passes their ARNs in `key_user_arns` by naming convention. |
| Administrators cannot use the data | The administrator statement has no `Encrypt` or `Decrypt`. `kms:ScheduleKeyDeletion` is allowed to administrators but denied to everyone except break glass. |
| Pool MFA, not group MFA | Cognito sets MFA per pool, so the split of the case statement is two pools (section 3.1). |
| Passwordless codes (ASM-272) | Email codes always; SMS codes only when the root supplies `field_sms_configuration`, because the SMS role needs an SNS sandbox exit and an external ID that this public module cannot hold. |
| Name aliases | PC-IAC-003 caps names at 28 characters. A key alias is `alias/<name_prefix>-<class>` without a type code, so that the longest class, `public-view`, fits with a 16 character prefix. |
| PC-IAC-001 and PC-IAC-005 | PC-IAC-001 requires `providers.tf` in every module; AGENTS.md forbids provider blocks in modules. `providers.tf` holds only a comment and the `aws.project` alias is declared in `versions.tf`. |
| `sample/` and `examples/` | PC-IAC-001 names `sample/` and PC-IAC-018 names `examples/`. The module uses `sample/`. |
| Checkov skips | Three IAM policy checks are skipped on the key policy document. In a key policy the resource `*` means the key itself, and every principal is explicit. |

## Not in this module

| Item | Owner |
|---|---|
| IoT policy of a farm node (ASM-271) | Ingestion module, B09 (ADR-003). The module only provides the revocation path. |
| IoT policy and grant topic of a drone kit | Drone service, A15 (PD-104). |
| The revocation function, the operations screen and the pre-authentication trigger | Application stacks. |
| Cognito app clients and Lambda triggers | Application stacks; they depend on callback URLs and functions that do not exist yet. |
| IAM Identity Center permission sets (`PlatformReadOnly`, `DeviceRevocation`, `IdentitySupport`, `Auditor`, `BreakGlass`) | Deferred (PD-270). They live in the management account with its own provider, and the module has one alias. |
| TLS policy of the IoT domain configuration and of API Gateway and CloudFront | The modules that own those endpoints (PD-100). |
| The `audit` key | Security account (A08). |

## Verification

The module declares the `aws.project` provider alias, so `terraform validate` runs through the consuming root in `sample/`. Format and plan-mode tests run on the module and on the sample, offline, with a mocked provider.

```bash
terraform fmt -check -recursive
terraform -chdir=modules/security init -backend=false
terraform -chdir=modules/security test
terraform -chdir=modules/security/sample init -backend=false
terraform -chdir=modules/security/sample validate
terraform -chdir=modules/security/sample test
trivy config modules/security
checkov -d modules/security --framework terraform
```
