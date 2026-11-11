# Single collection center association

One invocation represents one center connection in `pdn`. The root supplies its approved center key and canonical departmental /16. The module creates a workload-owned Transit Gateway VPC attachment, a hub-owned customer gateway, one two-tunnel VPN, and one single-entry prefix list. A hub-owned attachment accepter is added only when the owner accounts differ: five managed resources across accounts, four in one account. There is no loop over departments.

| Input | Contract |
|---|---|
| `client`, `project`, `environment`, `name_prefix`, `additional_tags` | Root governance, protected identity tags, permanent pdn context |
| `center` | One key and canonical IPv4 /16; the private root owns the approved catalog |
| `network` | `environment`, `account_id`, and reviewed B04 outputs `vpc_id`, `vpc_cidr_block`, `transit_attachment_subnet_ids` |
| `hub` | External network-account ID, Region, shared Transit Gateway ID, and matching public ACM private-certificate ARN |

The providers are explicit: `aws.project` owns the environment VPC attachment; `aws.network` owns acceptance, the customer gateway, VPN and prefix list. Roots must authenticate each alias to its declared account. Same-account use still injects both aliases. RAM sharing, Transit Gateway ownership/default route tables, certificate issuance and per-AZ subnet ownership remain external contracts, never guessed discoveries. The B04 adapter example consumes actual output expressions from the reviewed network module.

The connection requires certificate authentication, IKEv2 on both tunnels and static routing. No customer public IP, BGP relationship, plaintext PSK or private key is accepted. `preshared_key_storage = "SecretsManager"` also prevents a future provider-managed fallback PSK from using the standard storage mode. AWS provider 6.0.0 supports this argument and documents redacted computed PSK fields with Secrets Manager storage. Only public IDs are output; configuration XML and computed tunnel secrets are never output. Mock tests clear those computed fields; they do not prove real state secrecy or certificate possession. No apply is authorized.

Outputs are `vpc_attachment_id`, `vpn_connection_id`, `vpn_attachment_id`, `customer_gateway_id`, `center_prefix_list_id`, and `selected_center`. B07 owns Transit Gateway route tables, associations, static/blackhole routes, route propagation policy and firewall openings. The VPC attachment disables default association and propagation; the external hub must also prevent unwanted VPN defaults. `aws_vpn_connection_route` is not used for Transit Gateway routing. RAM sharing of prefix lists is an external contract. The module grants no center-to-center, dev, qa, or Buenaventura access.

```text
collection-center-association/
|-- main.tf, variables.tf, outputs.tf, versions.tf
|-- locals.tf, providers.tf, data.tf, CHANGELOG.md
|-- tests/association_unit_test.tftest.hcl
`-- sample/
    |-- complete local root and tests/association_sample_test.tftest.hcl
    `-- b04-integration/   actual reviewed B04 output adapter, synthetic hub
```

After installing the approved Terraform launcher and AWS provider 6.0.0, select its isolated validation context and run:

```text
terraform fmt -check -recursive
terraform -chdir=modules/collection-center-association init -backend=false -input=false
terraform -chdir=modules/collection-center-association test
terraform -chdir=modules/collection-center-association/sample init -backend=false -input=false
terraform -chdir=modules/collection-center-association/sample validate
terraform -chdir=modules/collection-center-association/sample test
terraform -chdir=modules/collection-center-association/sample/b04-integration init -backend=false -input=false
terraform -chdir=modules/collection-center-association/sample/b04-integration validate
terraform -chdir=modules/collection-center-association/sample/b04-integration test -var-file=terraform.tfvars
python scripts/verify-association.py
```

Every test is `command = plan` with `mock_provider`; all references are synthetic. Child aliases are validated through the sample root. The integrated fixture includes 163 B04 resources plus five B05 resources: 168 creates, zero updates, zero deletes. The three-center B04 CIDR catalog is addressing configuration, not three B05 connection instances. No cloud ownership, endpoint service availability, VPN connectivity, deployed prefix list or backend behavior is claimed.

No SemVer release exists. Local sources are confined to verification examples. Shared roots must consume a genuine reviewed tag; never replace a missing release with a branch or invented version.

Official pinned references: [VPN resource and secret storage](https://github.com/hashicorp/terraform-provider-aws/blob/v6.0.0/website/docs/r/vpn_connection.html.markdown), [customer gateway](https://github.com/hashicorp/terraform-provider-aws/blob/v6.0.0/website/docs/r/customer_gateway.html.markdown), [AWS certificate requirements](https://docs.aws.amazon.com/vpn/latest/s2svpn/cgw-options.html).
