# Network module (box D04)

Reference module for the network of one environment of the Aroma Pacifico pilot, built from the addressing plan and the cloud firewall policy of the architecture repository. It creates the VPC, eight tiers of subnets, routing, network ACLs and VPC endpoints. The transit gateway and its attachment, the prefix lists and the stack wiring are not part of this module (see "Not in this module").

The module declares no provider block; the consuming root supplies the `aws.project` alias. Every value comes from the root, with no environment defaults, so one module serves `dev`, `qa` and `pdn`. The values in `sample/` are synthetic because this repository is public.

## Contract

| Input | Type | Meaning |
|---|---|---|
| `client`, `project`, `environment` | `string` | Governance values; `environment` is `dev`, `qa` or `pdn`. |
| `name_prefix` | `string` | Prefix of every physical name, at most 16 characters. |
| `additional_tags` | `map(string)` | Extra tags merged into every taggable resource. |
| `vpc_cidr_block` | `string` | Environment VPC CIDR block inside 10.0.0.0/8, outside every collection center block. |
| `subnets` | `map(map(string))` | CIDR block per tier and Availability Zone slot (`az1` to `az3`); `az4` is reserved and rejected. |
| `collection_center_cidr_blocks` | `map(string)` | Collection center blocks that the VPC must not overlap. |
| `collection_center_summary_cidr_block` | `string` | One block that summarizes every center (10.40.0.0/13), routed through the transit gateway. |
| `collection_center_firewall_cidr_blocks` | `map(string)` | Firewall host (/32) of each center, for the administration ACL (CL-ADM-04). |
| `collection_center_ground_station_cidr_blocks` | `map(string)` | Ground station host (/32) of each center, for the drone and object ACLs (CL-DRN-04). |
| `transit_gateway_id` | `string` | Transit gateway of the network account. Null creates no route to the centers. |
| `data_store_ports` | `list(number)` | TCP ports the application tier may reach in the data tier (CL-DAT-02). Empty denies everything. |
| `interface_endpoints` | `map(object)` | Interface endpoints by short key, each with a service suffix and a tier. |
| `organization_id` | `string` | Organization admitted by the gateway endpoint policies. Never commit a real value. |
| `flow_logs` | `object` | CloudWatch Logs destination and IAM role for rejected traffic, or null to disable. |

Outputs: `vpc_id`, `vpc_cidr_block`, `availability_zone_ids`, `subnet_ids` and `subnet_cidr_blocks` by tier and slot, `route_table_ids`, `network_acl_ids`, `internet_gateway_id`, `transit_attachment_subnet_ids`, `gateway_endpoint_ids`, `interface_endpoint_ids`, `endpoint_security_group_ids` and `flow_log_id`.

## Tiers

| Tier | Name code | Internet route | Route to centers | ACL rows | Endpoints |
|---|---|---|---|---|---|
| `public_query` | `pubq` | Yes, the only tier | No | CL-PUB-04 | None |
| `telemetry_ingress` | `tlmi` | No | No | CL-TEL-04, deny all | None (CL-TEL-04) |
| `drone_object_ingress` | `droi` | No | Yes (reservation, PD-140) | CL-DRN-04 | None (ASM-140, PD-140) |
| `application` | `app` | No | Yes | CL-APP-03 | Interface |
| `data` | `data` | No | No | CL-DAT-01, CL-DAT-02 | None |
| `object_storage` | `objs` | No | Yes | CL-DRN-04 | Interface |
| `administration` | `adm` | No | Yes | CL-ADM-04 | Interface |
| `transit` | `tgw` | No | No | CL-LNK-08 | None |

There is no NAT gateway and no default route in a private tier (CL-EGR-01). Every ACL ends with an explicit deny in both directions (CL-DEF-01). Gateway endpoints for S3 and DynamoDB attach to the route tables of every tier except `public_query` and admit only resources of the organization (CL-DAT-03).

## Decisions

**PD-140: `drone_object_ingress` is a documented reservation.** The tier keeps its route to the collection centers and its network ACL (CL-LNK-07, CL-DRN-04) but holds no endpoint, because the ground station uses the endpoints in `application` and `object_storage` (drone service section 9, ASM-140). A later separation of drone uploads reuses the tier without renumbering.

**The `transit` tier carries no route to the transit gateway.** CL-LNK-07 lists only four tiers for that route, so the attachment subnets keep local routes. The module exposes `transit_attachment_subnet_ids` for the attachment, which belongs to the network account.

## Exceptions and open points for review

| Topic | Detail |
|---|---|
| Exception to PC-IAC-020 | The `application` ACL allows outbound TCP 443 to 0.0.0.0/0. CL-APP-03 states why: "outbound TCP 443 stays open because gateway endpoint destinations are AWS public ranges, which an ACL cannot name, and security groups narrow it." PC-IAC-020 section 2.2 forbids 0.0.0.0/0 in private networks. The rule is implemented as the firewall policy writes it. |
| Stateless return rules | Several tiers accept inbound TCP 1024 to 65535 from anywhere (CL-APP-03, CL-DRN-04) or from the center summary (CL-ADM-04), because a network ACL cannot track connections. The private tiers have no route to the internet gateway, and security groups, which are stateful, remain the first layer. Review that no service listens above 1023 in these tiers. |
| 28 character cap | PC-IAC-003 caps names at 28 characters but allows `client` up to 10 and `project` up to 15, which cannot fit the pattern `{client}-{project}-{environment}-{type}-{key}`. The module takes a `name_prefix` and limits it to 16 characters so that the longest suffix, 12 characters, still fits. |
| PC-IAC-001 and PC-IAC-005 | PC-IAC-001 requires `providers.tf` in every module; AGENTS.md forbids provider blocks in modules. `providers.tf` holds only a comment and the `aws.project` alias is declared in `versions.tf`. |
| `sample/` and `examples/` | PC-IAC-001 names `sample/` and PC-IAC-018 names `examples/`. The module uses `sample/`. |
| Terraform functions | Terraform 1.15 has no `cidrcontains` or `setequal`. Overlap and containment are checked by reducing blocks to integer ranges in preconditions, and subnets are only compared pairwise for duplicates. |

## Endpoint services

Re-checked against the AWS PrivateLink page (`docs.aws.amazon.com/vpc/latest/privatelink/aws-services-privatelink-support.html`) on 2026-11-10, for PD-120 and PD-200.

| Service suffix | Tier | Status |
|---|---|---|
| `execute-api` | `application` | Verified: listed on the page |
| `monitoring` | `administration` | Verified: listed on the page |
| `logs` | `administration` | Verified: listed on the page |
| `rolesanywhere` | `administration` | Verified: listed on the page |
| `s3` (interface) | `object_storage` | Verified: listed on the page |
| `cognito-idp` | `application` | **Unverified**: not listed on the page, and the Cognito page consulted does not state it |
| S3 and DynamoDB gateway type | Private tiers | Not part of this re-check |

PD-120 and PD-200 remain open in the decision log. The lead records the decision to start without the full re-check (ASM-211). Until `cognito-idp` is confirmed, treat its endpoint as unverified.

## Not in this module

The transit gateway, its VPC attachment and the route tables of the hub (CL-LNK-01 to 06) belong to the network account. Prefix lists and the center firewall rules belong to B07 and the collection center association (B05). The endpoint policies of `execute-api` and the S3 interface endpoint (CL-APP-02, CL-DRN-02) need the platform ARNs and bucket, and the Route 53 Resolver inbound endpoint (CL-ADM-01) is not a VPC endpoint. Until those policies exist, interface endpoints use the default endpoint policy, which allows every principal and every resource of the service. The HTTPS-only security groups and the stateless ACLs limit who can reach them, but not what a caller can do through them, so the policies are a required follow-up before any non-fixture use. These per endpoint policies stay out of this module because they depend on ARNs that do not exist yet. A common policy for all interface endpoints is deliberately not added either: a condition on `aws:ResourceOrgID` could break services that do not support that key, so it is left as a follow-up to design per service. The wiring in `aroma-pacifico-infrastructure` is B04b.

## Verification

The module declares the `aws.project` provider alias, so `terraform validate` runs through the consuming root in `sample/`. Format and plan-mode tests run on the module and on the sample, offline, with a mocked provider.

```bash
terraform fmt -check -recursive
terraform -chdir=modules/network init -backend=false
terraform -chdir=modules/network test
terraform -chdir=modules/network/sample init -backend=false
terraform -chdir=modules/network/sample validate
terraform -chdir=modules/network/sample test
```
