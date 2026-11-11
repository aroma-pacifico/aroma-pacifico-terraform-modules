# Network module (box D04)

Reference module for the VPC and subnets of one environment of the Aroma Pacifico pilot, built from the addressing plan in the architecture repository. It is delivered in parts under B04a; this part creates the VPC and the eight-tier subnet layout. Routing, network ACLs and VPC endpoints follow in later parts, and the stack wiring is B04b.

## Contract

| Input | Type | Meaning |
|---|---|---|
| `client`, `project`, `environment` | `string` | Governance values; `environment` is `dev`, `qa` or `pdn`. |
| `name_prefix` | `string` | Prefix of every physical name, at most 16 characters (PC-IAC-003 28 character cap). |
| `additional_tags` | `map(string)` | Extra tags merged into every taggable resource. |
| `vpc_cidr_block` | `string` | Environment VPC CIDR block, outside every collection center block. |
| `subnets` | `map(map(string))` | CIDR block per tier and Availability Zone slot (`az1` to `az3`); `az4` is rejected. |
| `collection_center_cidr_blocks` | `map(string)` | Collection center blocks that the VPC must not overlap. |

The eight tiers are `public_query`, `telemetry_ingress`, `drone_object_ingress`, `application`, `data`, `object_storage`, `administration` and `transit`. The module declares no provider block; the consuming root supplies `aws.project`.

## Verification

The module declares the `aws.project` provider alias, so `terraform validate` runs through the consuming root in `sample/`, not on the module directory alone. Format and plan-mode tests run on the module and on the sample, offline, with a mocked provider.

```bash
terraform fmt -check -recursive
terraform -chdir=modules/network init -backend=false
terraform -chdir=modules/network test
terraform -chdir=modules/network/sample init -backend=false
terraform -chdir=modules/network/sample validate
terraform -chdir=modules/network/sample test
```
