# Inference functions module (box D10)

Reference module for the event-driven inference function pattern of Part E of the case statement, designed in `docs/inference-functions.md` of the architecture repository (section 11, "Epic 6 function pattern"). For each entry of `functions` it creates the trigger queue and its dead-letter queue, an encrypted log group, a least-privilege execution role, a Lambda function and the SQS event source mapping that invokes it. Nothing is trained and nothing runs between events: there is no endpoint, no provisioned concurrency and no instance waiting for objects.

The module declares no provider block; the consuming root supplies the `aws.project` alias. Every value comes from the root, so one module serves `dev`, `qa` and `pdn`. The function code is outside the module: each entry names its package, and a prompt version ships inside that package (ASM-179).

## What the pattern covers

| Element of the pattern | How the module implements it |
|---|---|
| Event trigger | An SQS queue per function plus a Lambda event source mapping. Upstream rules, pipes and topic rules target `queue_arns`; the optional `queue_senders` names the AWS service and the source ARN allowed to send, and a queue policy denies plain HTTP. |
| Read permission | Per function: `s3:GetObject` and `s3:GetObjectVersion` on explicit object ARNs, `dynamodb:GetItem` and `dynamodb:Query` on explicit table ARNs, `kms:Decrypt` on the key classes named in `read.kms_classes`. |
| Invocation | `bedrock:InvokeModel` on the one foundation model ARN built from the model identifier and the Region of the provider. Inference profile identifiers are rejected. |
| Result write | `dynamodb:PutItem`, `dynamodb:UpdateItem` and `dynamodb:ConditionCheckItem` (the permissions behind `TransactWriteItems`), `sns:Publish` on explicit topic ARNs, and `kms:GenerateDataKey` on the write classes. |
| Result record | The attribute names of the timestamp, the confidence and the source object identifier (`result_record_attributes`, default `result_at`, `confidence` and `source` from section 5 of the design) reach the function as `RESULT_TIMESTAMP_ATTRIBUTE`, `RESULT_CONFIDENCE_ATTRIBUTE` and `RESULT_SOURCE_OBJECT_ATTRIBUTE`, and are exposed as an output. |
| Retries and dead-letter queue | Visibility timeout of six times the function timeout, `maxReceiveCount` per function (design value 5), a dead-letter queue per function that keeps messages 14 days and accepts redrive only from its source queue, partial batch responses, and `BACKOFF_BASE_SECONDS` for the exponential visibility backoff that the function applies. |
| Never granted | An explicit deny on `s3:PutObject`, `s3:DeleteObject` and `s3:DeleteObjectVersion`, so a function cannot alter its source; an explicit deny on the `personal` and `restricted` keys, which validation also keeps out of `read.kms_classes` and `write.kms_classes`. |

## Contract

| Input | Type | Meaning |
|---|---|---|
| `client`, `project`, `environment` | `string` | Governance values; `environment` is `dev`, `qa` or `pdn`. |
| `name_prefix` | `string` | Prefix of every physical name, at most 16 characters. Names follow `{prefix}-{lmb\|rol\|sqs\|dlq}-{key}` and stay within 28 characters. |
| `additional_tags` | `map(string)` | Extra tags merged into every taggable resource. |
| `functions` | `map(object)` | One entry per function, keyed by at most 6 lowercase alphanumeric characters. Fields: `description`, `package`, `handler`, `runtime`, `timeout_seconds`, `memory_mb`, `batch_size`, `reserved_concurrency`, `max_receive_count`, `backoff_base_seconds`, `read`, `write`, `inference.model_id`, `queue_senders`, `environment_variables`. |
| `kms_key_arns` | `map(string)` | Key ARNs by data class, the `kms_key_arns` output of the security module. `records` and `logs` are required. |
| `log_retention_days` | `number` | Log group retention in days; never 0. |
| `result_record_attributes` | `object` | Names of the three result attributes. |
| `permissions_boundary_arn` | `string` | Optional boundary for the function roles. |

Outputs: `role_arns`, `key_user_arns`, `function_arns`, `function_names`, `queue_arns`, `queue_names`, `queue_urls`, `dead_letter_queue_arns`, `dead_letter_queue_names`, `event_source_mapping_uuids`, `log_group_names` and `result_record_attributes`.

## Wiring with the security module (B06)

The security module creates no function role. This module builds the roles, and its `key_user_arns` output has the shape of the `key_user_arns` input of the security module, so the root passes the role ARNs there and the key policies name them. The output depends only on the roles, and the role policies are separate resources, so the two modules form no cycle even though this module also consumes `kms_key_arns`. The security module also owns the key policy statements that let SQS, CloudWatch Logs and the upstream senders use the `records` and `logs` keys.

## Decisions

The design values (timeouts, concurrency, receive count, 14 day retention, batch sizes) come from ASM-160 to ASM-163 and sections 4 to 6 of the design; the module takes them as inputs with the drone function values as defaults and does not measure anything. B10 codes the pattern generically: the telemetry threshold function is the coded example of PD-161, and the sample also lists the three drone functions, whose triggers (mission stream, pipe, custom bus and rules) belong to the ingestion and drone work, not to this module.

| Decision | Reason |
|---|---|
| One role per function, with separate policy resources | Each function has different read and write targets (design section 4), and separate policy resources keep `key_user_arns` free of cycles. |
| Reserved concurrency, not provisioned concurrency | Section 6.1 bounds the parallel Bedrock calls per function; provisioned concurrency would be persistent compute. |
| Policies as plain JSON built in `locals.tf` | The plan-mode tests assert the statements; empty grants add no statement. |
| Lambda checks skipped in `main.tf` | The dead-letter queue sits on the source queue, the functions are non-VPC by design, and code signing and X-Ray are outside the design; each skip carries its reason. |

## Verification

```bash
terraform fmt -check -recursive modules/inference-functions
terraform -chdir=modules/inference-functions init -backend=false
terraform -chdir=modules/inference-functions test
terraform -chdir=modules/inference-functions/sample init -backend=false
terraform -chdir=modules/inference-functions/sample validate
terraform -chdir=modules/inference-functions/sample test
trivy config modules/inference-functions
checkov -d modules/inference-functions --framework terraform
```
