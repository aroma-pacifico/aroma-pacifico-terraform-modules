# Telemetry ingestion module (box D09)

Reference module for the single pattern of Epic 6, chosen in ADR-003: accepting a farm reading and persisting it durably. It codes the boundary of the farm telemetry pattern of the architecture repository (`docs/adr/adr-003-iac-tool-remote-state-and-pattern-module.md`, section "Pattern module: telemetry ingestion"; `docs/connectivity.md` section 4; `docs/farm-monitoring.md` sections 3 and 6.6): the IoT Core data endpoint with its TLS policy, the policy that lets a node publish as itself, the topic rule, the telemetry table, the rule error queue and the IoT Core log group.

The module declares no provider block; the consuming root supplies the `aws.project` alias. Every environment value comes from the root, so one module serves `dev`, `qa` and `pdn`. The values in `sample/` are synthetic because this repository is public. Nothing in the module needs a secret: node private keys never leave the devices, and the module registers no certificate.

## Scope and exclusions

The module implements the ingestion pattern only. The sack lookup (public lookup, buyer view) is the other pattern of the case statement and is not coded here (ADR-003, PD-016).

| Included | Detail |
|---|---|
| Device policy (`aws_iot_policy`) | One policy for every node. `iot:Connect` only when the client ID equals the attached thing name; `iot:Publish` only to `<topic_namespace>/<thing name>`, built with `${iot:Connection.Thing.ThingName}`. No subscribe, no receive. |
| Data endpoint (`aws_iot_domain_configuration`) | Service type `DATA` with a predefined TLS policy whose minimum is TLS 1.2 (CL-TEL-01, CL-TEL-02). The default protocol settings admit MQTT over TLS with an X.509 client certificate on port 8883 and, with ALPN, on port 443. |
| Topic rule (`aws_iot_topic_rule`) | Two independent actions per reading (ASM-161, PD-161): a `dynamodbv2` PutItem to the telemetry table and an SQS action to the threshold queue. Its error action sends the message to the rule error queue. Thresholds are never in the SQL. |
| Telemetry table (`aws_dynamodb_table`) | On demand, keyed by node and original reading timestamp, encrypted with the `telemetry` key, point-in-time recovery, deletion protection, `prevent_destroy`, time to live on `expires_at`. |
| Rule error queue (`aws_sqs_queue`) | Encrypted with the `telemetry` key, plain HTTP denied, 14 day retention. |
| IoT Core logging (`aws_cloudwatch_log_group`, `aws_iot_logging_options`) | The `AWSIotLogsV2` group encrypted with the `logs` key, and account logging at level `ERROR` (PD-073). |

| Excluded | Where it lives |
|---|---|
| Thing, X.509 certificate from a CSR, attachment of the policy | Farm module (B08). The module outputs the policy name and topic template it needs. |
| IAM roles of the rule and of IoT logging, KMS keys and their key policies | Security module (B06), from `v0.5.0` for the two roles. Roles and keys are inputs. |
| Threshold queue, its dead-letter queue and the function | Inference-functions module (B10). The queue URL is an input; the rule ARN is an output. |
| Alert store, thresholds table, SNS alert topic, farmer channel | Architecture designs A14 and A17; not Epic 6. |
| Revocation of a certificate | Operational procedure (A09), through the revocation role of the security module. |
| Silent-node alarm, alarms on the error queue, dashboards | Observability (A21). |
| WAF | Does not apply to IoT Core; the API web ACL (CL-TEL-03) is in `firewall-rules`. |
| `telemetry_ingress` interface endpoint, network ACL CL-TEL-04 | Not created in the pilot (CL-TEL-04); the tier ACL is in the `network` module. |
| Device firmware, store-and-forward buffer | Out of scope of the case statement; the farm module only exposes the contract. |

The module creates no IAM role, security group, VPC or load balancer (PC-IAC-023). It creates one account-level setting, IoT Core logging, so one ingestion module serves one account and Region.

## Contract

| Input | Type | Meaning |
|---|---|---|
| `client`, `project`, `environment`, `name_prefix` | `string` | Governance values and the physical name prefix (at most 16 characters). |
| `additional_tags` | `map(string)` | Extra tags merged into every taggable resource. |
| `kms_key_arns` | `map(string)` | The `kms_key_arns` output of the security module; `telemetry` and `logs` are required. |
| `rule_role_arn` | `string` | Role the topic rule assumes (see below). |
| `logging_role_arn` | `string` | Role IoT Core assumes to write its logs. |
| `threshold_queue_url` | `string` | Queue URL from the `queue_urls` output of the inference-functions module. |
| `topic_namespace` | `string` | Topic levels above the thing name, for example one or two levels. |
| `tls_security_policy` | `string` | Predefined policy with a TLS 1.2 or later minimum (PD-100). |
| `retention_days` | `number` | Days before time to live deletes a reading. No default. |
| `log_retention_days` | `number` | Retention of the IoT log group; never 0. |
| `error_queue_retention_days` | `number` | Default 14, the design value and the SQS maximum. |
| `telemetry_attributes` | `object` | Attribute names (`node_id`, `reading_at`, `received_at`, `expires_at`) and the sort key type (`S` or `N`). |

| Output | Meaning |
|---|---|
| `ingestion` | Object with `environment`, `endpoint`, `policy_name` and `topic_template`: exactly the `ingestion` input of the farm module. |
| `endpoint`, `device_policy_name`, `device_policy_arn`, `topic_template`, `topic_filter` | The parts of `ingestion` and the rule filter. |
| `topic_rule_arn`, `topic_rule_name` | Built from the name, so the root can allow the rule on the threshold queue without a dependency cycle. |
| `telemetry_table_arn`, `telemetry_table_name`, `item_attributes` | For the read permission of the threshold function and the item shape. |
| `error_queue_arn`, `error_queue_name`, `error_queue_url` | For the replay of failed readings and the alarm on the first message. |
| `domain_configuration_name`, `log_group_name`, `rule_catalog` | Domain configuration, log group, and the policy rows CL-TEL-01 and CL-TEL-02 with their audit flag. |

## Accepted message

The device contract of the farm module leaves the wire format to this module. A reading is a JSON object published with QoS 1 to `<topic_namespace>/<thing name>` that carries the original reading timestamp under the `reading_at` name (an ISO 8601 UTC string, or a number if `reading_at_type` is `N`), a sequence number and the measured values. The rule adds `node_id` (taken from the topic, so a node cannot write into another node's partition), `iot_received_at`, `expires_at`, `certificate_principal`, `client_id` and `source_ip` (PD-073). The payload must not use those names. A message without `reading_at` fails the table write and lands in the rule error queue. A reading published twice overwrites the same item, which is how the 24 hour drain stays idempotent.

## Wiring (what the roots must supply)

This module creates no IAM role. `modules/security` at tag `v0.5.0` or later creates both roles, and the root passes their ARNs from its outputs `iot_rule_role_arn` and `iot_logging_role_arn` (the security stack exposes the same names) to `rule_role_arn` and `logging_role_arn`.

| Role | What the security module grants | Key policy |
|---|---|---|
| Topic rule role (`rule_role_arn`) | Trust for `iot.amazonaws.com`, limited to the one topic rule of the prefix. `dynamodb:PutItem` on the telemetry table, `sqs:SendMessage` on the threshold queue and on the rule error queue, and `kms:Decrypt` and `kms:GenerateDataKey` on the `telemetry` and `records` keys. | The security module adds the role to the `UseKey` statement of the `telemetry` and `records` key policies by itself. The root must not repeat it in `key_user_arns` of the module (`key_user_role_names` of the stack). |
| IoT logging role (`logging_role_arn`) | Trust for `iot.amazonaws.com`, limited to the account. `logs:CreateLogStream`, `logs:DescribeLogStreams` and `logs:PutLogEvents` on the `AWSIotLogsV2` group, which this module creates. | None. The `logs` key policy admits the CloudWatch Logs service, so the role needs no key grant. |

The grants are built from names, not from inputs of the security module: the table `<name_prefix>-ddb-tel`, the error queue `<name_prefix>-iot-dlq`, the threshold queue `<name_prefix>-sqs-thresh` (function key `thresh` of the inference-functions module) and the topic rule `<name_prefix with underscores>_iot_rul`. The roles can therefore be scoped before this module is applied, and a different `name_prefix` or function key in the root has to be matched in the security module.

The inference-functions module allows IoT to send to the threshold queue through `queue_senders` (`iot.amazonaws.com` with `topic_rule_arn` as the source). Pass `topic_rule_arn` from this module, which does not depend on the queue, so the two modules form no cycle. The farm module takes `ingestion` as its `ingestion` input.

## Exceptions to the binding rules

| Rule | Exception | Reason |
|---|---|---|
| PC-IAC-003 | The topic rule name uses underscores and the log group is named `AWSIotLogsV2`. | IoT rule names allow no hyphen, and IoT Core writes to a log group of that fixed name. |
| PC-IAC-020 | No WAF and no VPC endpoint. | WAF does not apply to the IoT Core endpoint (ADR-003); the pilot creates no `telemetry_ingress` endpoint (CL-TEL-04). |

## Assumptions and open points

| Point | State |
|---|---|
| Attribute names `node_id`, `reading_at`, `received_at`, `expires_at` | `reading_at` and `iot_received_at` follow the observability design; `node_id` and `expires_at` are assumed. Overridable through `telemetry_attributes`. |
| Sort key as an ISO 8601 string | Assumed, because it sorts in time order. A numeric timestamp is supported by `reading_at_type`. |
| Retention counted from receive time | The design counts 5 years from the reading; the rule cannot parse an ISO timestamp, so it counts from receipt, at most 24 hours later. |
| Topic namespace, TLS policy name | Not fixed by the design; the root states them (PD-100). |
| IoT SQL functions and policy names | Taken from the AWS documentation page of the SQL functions and of the TLS policies; PD-021 and PD-130 still ask for a live re-check of availability and quotas before any deployment. |

## Verification

```bash
terraform fmt -check -recursive
terraform -chdir=modules/telemetry-ingestion/sample init -backend=false
terraform -chdir=modules/telemetry-ingestion/sample validate
terraform -chdir=modules/telemetry-ingestion test
terraform -chdir=modules/telemetry-ingestion/sample test
```

The tests run on a mock provider and need no credentials. CI also plans `sample/` against the Floci emulator with the `test` credentials (PC-IAC-028).
