# Firewall rules module (box D07)

Reference module for the permanent cloud firewall rules of one environment of the Aroma Pacifico pilot, built from the cloud policy table of the architecture repository (`docs/firewall-policy.md`, section 5.2). It creates the collection center prefix lists, the security groups that the network module does not own, two interface endpoint policies and the two AWS WAF web ACLs. Every rule it creates is tagged and cataloged as permanent or temporary, with its pre-production audit flag.

The module declares no provider block; the consuming root supplies the `aws.project` alias. Every value comes from the root, with no environment defaults, so one module serves `dev`, `qa` and `pdn`. The values in `sample/` are synthetic because this repository is public.

## Scope and exclusions

PD-122 puts the permanent cloud rules across several modules. This table says which policy rows this module codes and where the others live, so no row is coded twice.

| Policy row | Mechanism | Where it is coded |
|---|---|---|
| CL-ADM-01 | Security group of the Resolver inbound endpoint | This module (`resolver`) |
| CL-ADM-03 | Security group of the management session host | This module (`session_host`) |
| CL-DAT-02 | Security group of the data store | This module (`data_store`) |
| CL-PUB-03 | Load balancer group, CloudFront origin only | This module, only if `enable_cloudfront_origin_rule` |
| CL-APP-02, CL-DRN-02 | Interface endpoint policies | This module, only if the root names the endpoint |
| CL-PUB-01, CL-TEL-03 | WAF web ACLs of the public lookup and the API | This module |
| CL-APP-03, CL-DRN-04, CL-ADM-04, CL-PUB-04, CL-DAT-01, CL-TEL-04, CL-LNK-08 | Network ACLs | `network` module |
| CL-APP-01, CL-DRN-01, CL-ADM-02 | Security groups of the interface endpoints | `network` module |
| CL-DAT-03 | Gateway endpoint policies | `network` module |
| CL-DEF-02 | Flow log of rejected traffic | `network` module |
| CL-LNK-01 to CL-LNK-07 | Transit gateway routes and VPN | Collection center association module (B05) |
| CL-TEL-01, CL-TEL-02 | IoT Core domain and policy | Telemetry ingestion module (B09) |
| CL-ADM-05, CL-EGR-01, CL-DEF-01 | AWS Config rules, absence of NAT, implicit deny | Not resources of this module |

Center firewall rules (CC rows) are device configuration and are not coded in Terraform (PD-122). The module creates no WAF association, no Resolver endpoint, no load balancer, no data store and no bucket: it publishes the security group IDs and web ACL ARNs that the owning stacks attach.

## Contract

| Input | Type | Meaning |
|---|---|---|
| `client`, `project`, `environment`, `name_prefix` | `string` | Governance values and the physical name prefix (at most 16 characters). |
| `additional_tags` | `map(string)` | Extra tags merged into every taggable resource. |
| `vpc_id` | `string` | VPC of the environment, from the network stack. |
| `collection_centers` | `map(object)` | Per center: firewall host, ground station host, logistics block, staff blocks, device management blocks and guest blocks. |
| `application_cidr_blocks`, `data_store_ports` | `list` | Sources and ports admitted by the data store group (CL-DAT-02). |
| `api_endpoint`, `drone_object_endpoint` | `object` or `null` | Endpoint IDs and the ARNs their policies admit. Null attaches no policy. |
| `enable_cloudfront_origin_rule` | `bool` | Creates the load balancer group of CL-PUB-03. Default `false`. |
| `waf_scope` | `string` | `CLOUDFRONT` or `REGIONAL`. |
| `lookup_allowed_path_prefixes`, `lookup_rate_scope_path`, `lookup_rate_limit` | `list`, `string`, `number` | Allowed paths, rate scope and the per-IP limit of the public lookup (ASM-155: 100 in 5 minutes on `/s/`). |
| `api_rate_limit` | `number` | Per-IP limit of the API front door. The design gives no value (see the open point below). |
| `temporary_rules` | `map(object)` | Temporary ingress rules, each with a rule ID, a source prefix list and a removal condition. Default empty. |

| Output | Meaning |
|---|---|
| `prefix_list_ids` | The five prefix lists: `cc_device_mgmt`, `cc_firewalls`, `cc_ground_stations`, `cc_logistics`, `cc_staff`. |
| `security_group_ids` | `session_host`, `resolver`, `data_store` and, when enabled, `load_balancer`. |
| `web_acl_arns` | `lookup` and `api`. |
| `rule_catalog` | Every rule created, keyed by policy ID, with group, mechanism, validity and audit flag. |
| `temporary_rule_ids` | IDs of the temporary rules. |

## Permanent and temporary rules

Each resource that implements a rule carries the tags `FirewallRule` (the policy ID), `Validity` (`permanent` or `temporary`) and `AuditBeforeProduction` (`true` for the rows the policy marks Audit, PD-125). The same facts are in the `rule_catalog` output. Epic 6 codes only permanent rules (PD-122); a temporary rule is passed through `temporary_rules`, must state the condition that removes it (tagged `RemovalCondition`), and is added and removed as a production change with its own release note.

## Guests never reach internal segments

The `collection_centers` input lists the guest and transporter blocks of each center. A numeric range check compares them with every address that enters a prefix list; if one overlaps, the prefix lists fail their precondition and the plan stops. No rule in the module references a guest block.

## Exceptions to the binding rules

| Rule | Exception | Reason |
|---|---|---|
| PC-IAC-003 | The WAF metric names repeat the name prefix and a short rule key. | AWS WAF requires a metric name per rule; they stay under the 28 character cap of physical names except where AWS allows up to 128. |
| PC-IAC-020 | The WAF web ACLs have no logging configuration. | Logging needs a destination owned by the security stack (`logs` key); the root adds it when that stack publishes it. |

## Open points

| Point | State |
|---|---|
| Rate limit of the API front door | The architecture gives managed groups and "a rate-based rule" for CL-TEL-03 but no threshold. The root supplies `api_rate_limit`; the value must be logged as an assumption in the architecture decision log before the stack uses it. |
| PD-051 (load balancer in front of the lookup) | Decides `enable_cloudfront_origin_rule`. |
| PD-123 (management session host) | The module creates only the host's security group, not the host. |

## Verification

```bash
terraform fmt -check -recursive
terraform -chdir=modules/firewall-rules/sample init -backend=false
terraform -chdir=modules/firewall-rules/sample validate
terraform -chdir=modules/firewall-rules test
terraform -chdir=modules/firewall-rules/sample test
```

The tests run on a mock provider and need no credentials.
