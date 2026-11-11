# B05 final plan-only delivery evidence

Refs aroma-pacifico/aroma-pacifico-roadmap#25. Status: **TECHNICALLY COMPLETE FOR PLAN-ONLY DELIVERY**; independent acceptance pending.

## Implementation and actual dependencies

The resource module is `modules/collection-center-association`; the private root retains the approved Cauca/Huila/Tolima catalog and composes one selected object. Permanent links target pdn only. Dev and permanent QA connections are rejected; the approved temporary QA logistics route belongs to B07 and reuses the exposed attachment references. No automatic all-center or Buenaventura infrastructure exists.

B04 is now published on main. The complete B04 adapter invokes the unchanged real network module and feeds its `vpc_id`, `vpc_cidr_block`, and `transit_attachment_subnet_ids` outputs directly to B05. The hub, account and certificate references remain synthetic because concrete ownership/RAM/certificate inputs are external. Nothing is presented as a real VPC, certificate or account.

The private `association-template/` has Region/tag/environment inputs, typed B04/hub contracts, account-validated plan-role inputs, two aliased providers, singular selection, granular B07 outputs and a future S3 declaration. No release exists; the production module source remains `REQUIRED_REVIEWED_RELEASE`. The Python verifier stages only a disposable local copy and omits S3.

## Resource ownership

| Resource | Cross-account count | Provider owner |
|---|---:|---|
| aws_ec2_transit_gateway_vpc_attachment.environment | 1 | aws.project, workload account |
| aws_ec2_transit_gateway_vpc_attachment_accepter.environment | 1 | aws.network, hub account; omitted for same-account use |
| aws_customer_gateway.center | 1 | aws.network |
| aws_vpn_connection.center | 1 | aws.network; one connection contains two tunnels |
| aws_ec2_managed_prefix_list.center | 1 | aws.network; one selected /16 entry |

No Transit Gateway, route, route table, firewall, RAM share, CA or certificate is created. B07 consumes `vpc_attachment_id`, `vpn_attachment_id`, `vpn_connection_id`, `customer_gateway_id`, `center_prefix_list_id`, and selected-center metadata. The VPC attachment disables default association/propagation. External hub defaults must also prevent unapproved VPN propagation.

## Actual plan inventory

All nonempty graphs use Terraform 1.15.8, AWS 6.0.0, synthetic fixtures, mock providers, `command=plan`, assertion PASS and verifier exit 0. No update/delete/replacement appears.

| Root / run | Environment | Input fixture | Expected creates | Actual creates / updates / deletes | Assertions |
|---|---|---|---:|---|---|
| Child cross_account_graph | pdn | tests/association_unit_test.tftest.hcl | 5 | 5 / 0 / 0 | Exact families, aliases, prefix, certificate, IKEv2/static/secret storage |
| Child same_account_graph | pdn | same native test file | 4 | 4 / 0 / 0 | No redundant accepter |
| Complete sample single_association | pdn | sample/tests/association_sample_test.tftest.hcl | 5 | 5 / 0 / 0 | Provider injection and B07 outputs |
| Actual B04 output adapter reviewed_b04_outputs | pdn | sample/b04-integration/terraform.tfvars and native test | 168 | 168 / 0 / 0 | 163 B04 + exactly 5 B05; direct real output wiring |
| Private staged cauca_connection | pdn | association-template native test; selected Cauca /16 | 5 | 5 / 0 / 0 | One matching department/prefix/VPN and all tags |
| Private staged huila_connection | pdn | same native test; selected Huila /16 | 5 | 5 / 0 / 0 | No connection resources for other departments |
| Private staged tolima_connection | pdn | same native test; selected Tolima /16 | 5 | 5 / 0 / 0 | Correct output contract and exact graph |
| Existing selection-only root, three center runs | pdn | tests/selection_unit_test.tftest.hcl; AWS 6.72.0 | 0 | 0 / 0 / 0 | Catalog/selection validation only; never counted as connection evidence |

## Executed verification

```text
terraform fmt -check -recursive: exit 0
child/sample/B04 integration init -backend=false -input=false: exit 0
both consuming roots validate: Success! The configuration is valid.
child terraform test: Success! 8 passed, 0 failed.
sample terraform test: Success! 1 passed, 0 failed.
B04 integration terraform test -var-file=terraform.tfvars: Success! 1 passed, 0 failed.
private selection root terraform test: Success! 9 passed, 0 failed.
python scripts/verify-association.py: exact 5/4/5/168-create graphs; exit 0
python scripts/verify-d05.py --module-root <local-association-directory>: 3 full root plans and 6 rejection fixtures; exit 0
tflint with AWS ruleset 0.44.0: all three module/composition roots exit 0
Trivy B05 leaf: 51 successes, 0 failures; exit 0
Trivy reviewed B04+B05 fixture: 70 successes, 1 MEDIUM AWS-0178; exit 1
git diff --check: exit 0
```

Native negative scenarios reject dev, permanent QA, noncanonical /16, empty transit-subnet set, VPC/center overlap and missing certificate. Six full private-root rejection fixtures verify multi-center lists, Buenaventura, wrong departmental CIDR, missing certificate, dev and permanent QA. The root's original nine selection scenarios are retained. All negative fixtures produce expected errors; their partial/absent graphs are not successful connection plans.

## Security and CI correction

The actual pinned AWS 6.0.0 schema supports certificate_arn and preshared_key_storage. Certificate-based customer authentication and IKEv2 are mandatory. No plaintext PSK input exists; SecretsManager storage is configured as additional protection against standard-storage fallback. No configuration XML, PSK or private key is output. Mock secret fields are empty; this does not prove real state contents or possession of the certificate private key. [Pinned provider behavior](https://github.com/hashicorp/terraform-provider-aws/blob/v6.0.0/website/docs/r/vpn_connection.html.markdown) and [AWS certificate requirements](https://docs.aws.amazon.com/vpn/latest/s2svpn/cgw-options.html) are documented.

The inherited MEDIUM finding concerns B04's disabled optional flow logs without a supplied destination. No invented logging destination or change to another owner's module is made. B05's own graph has no findings. The B04 three-department CIDR catalog is configuration, not three B05 connection instances.

Newly merged CI initially provided only aws.project during standalone child validation. The user authorized the narrow PR #17 fix: generate temporary validation stubs for every declared alias, preserve all tests/gates, then remove the stubs. Regression: old block fails with missing network provider; the exact amended shell block validates successfully. The child remains provider-free. The new PR title was also corrected to allowed iac scope. The assigned sample is registered for the inherited Infracost workflow; no price is invented.

## Acceptance criteria

| Original criterion | Status | Implemented code | Relevant test / plan | Security evidence | Remaining limitation |
|---|---|---|---|---|---|
| The code parameterizes the association with a single collection center per run. | PASS | Singular typed center and root invocation | Exact 5-resource private plans; 4-resource same-account case | Protected center/environment tags | AWS ownership remains synthetic |
| The association respects the addressing block of the corresponding department. | PASS | Private approved catalog; canonical /16 and overlap validation | Three matching department/VPN/prefix graphs; wrong CIDR rejected | No route expansion or BGP learning | B07 implements allowed/blackhole routes separately |
| The module does not instantiate the 3 centers or any infrastructure in Buenaventura. | PASS | No center inventory iteration; one prefix entry | Whitelisted exact graph; multi-center/Buenaventura rejection | No dev or permanent QA connection | Generic public module relies on the approved private catalog |
| The plan exposes the resources or connections needed for the cloud-to-collection-center link. | PASS | Complete connection resources and granular B07 outputs | Actual mocked 5-create root and 168-create B04 adapter | Certificate/IKEv2/static/alias checks; leaf scan clean | No live connectivity or routing claim |

## Reproduction and review

Initialize child, sample and B04 integration backend-disabled through the approved launcher, then run their native tests and `python scripts/verify-association.py`. The integrated test uses `-var-file=terraform.tfvars`. From the infrastructure checkout, run `python scripts/verify-d05.py --module-root <local-module-directory>`. This stages a complete isolated root and tests every department separately. No real identifiers or cloud credentials are needed.

PRs: [infrastructure #4](https://github.com/aroma-pacifico/aroma-pacifico-infrastructure/pull/4), [modules #17](https://github.com/aroma-pacifico/aroma-pacifico-terraform-modules/pull/17). Keep Draft pending independent review, owner decisions and acceptance. Reviewed release, real RAM/hub/certificate references and B07 routes are future shared-integration contracts, not reasons to require deployment for this scope.


## Delivery boundary and governance

Delivery date: 2026-11-11. Technical implementation is complete for the confirmed plan-only scope; independent acceptance remains pending. Every resource plan is **OFFLINE MOCKED TERRAFORM PLAN**. No authenticated AWS plan, cloud deployment, backend-enabled initialization, migration, import, state mutation or unlock was run. No real AWS credentials were used. No issue is closed and no PR is merged.

The current canonical constitution explicitly records faculty-confirmed plan-only delivery and 27 IaC rules, including PC-IAC-027. Current main governance was merged verbatim; no downstream rules were edited. ADR-003/PD-019 still need SR1/SR2 to record the mock-only evidence interpretation in the architecture decision log. A mocked pdn fixture is not the account plan restricted to qa by ASM-051. Runtime backend, VPN and MQTT behavior is not established by these tests.

All local Terraform commands used the approved AutoDev launcher through a checksum-identical disposable clone. The shared dispatcher, shim and settings fingerprints remained unchanged. Operational caches and the original root .terraform directories were left alone. AWS credential variables and inherited Terraform CLI overrides were removed; configuration/credential file paths pointed to absent fixture files and EC2 metadata was disabled. Provider 6.0.0 was reused from a read-only installed mirror with committed checksums; no fresh signature verification is claimed for it. B01's unchanged AWS 6.72.0 locks were initialized backend-disabled using a HashiCorp-signed registry download, then reused in disposable cache space.

## Verification environment

| Item | Actual value |
|---|---|
| Terraform | 1.15.8, windows_amd64; core floor >=1.14.0 |
| Resource graph provider | AWS 6.0.0; local consuming roots pin ~>6.0.0; children accept >=6.0.0 |
| B01 scaffold provider | AWS 6.72.0; existing ~>6.0 locks preserved |
| TFLint | 0.65.0, bundled Terraform rules and explicit current config with AWS ruleset 0.44.0 |
| Trivy | 0.76.2, cached checks; no findings suppressed |
| Python / public CSR verifier | Python 3.13; installed OpenSSL verifies both fixture signatures |
| Initialization | -backend=false -input=false; no remote-state access |

The settled shared suite contains 78 commands: 76 exit 0, and two Trivy commands exit 1 for the explicitly retained findings below. All native Terraform tests pass. Additional current-config AWS lint checks pass for all seven story roots. The B03 environment-secret checker passes in both infrastructure worktrees. Static hygiene finds no new private-key material, access-key pattern, emoji or public account literal. Child aliases are validated through consuming roots, never by adding provider blocks to the reusable modules.

## Failure history and corrections

| Observed failure | Correction and final evidence |
|---|---|
| B05 variable-validation dependency cycle and fixture syntax | Evaluate CIDR intervals directly from inputs; valid and overlapping/noncanonical CIDR regressions pass |
| PowerShell split an unquoted -var-file argument | Quote the full argument; final native and Python commands pass |
| New explicit root plan roles were initially absent from the fixture | Add computed synthetic role references and same-account validation; full root plans and rejection fixtures pass |
| Verification harness treated expected-error partial plans as successful graph evidence | Assert every required positive graph by run name and exact resource family; retain all negative native expectations |
| Mirror lacked B01's newly pinned 6.72.0 | Install the signed pinned release without backend access; retain existing locks |
| B01 environment inputs were unused in empty B02 roots | Use the explicit environment in provider default tags; four root lint checks pass |
| Initial recursive B05 security scan lacked nested-root variables | Final leaf and B04 composition scans have separate complete inputs; inherited finding remains visible |
| Optional Python cryptography package absent | Verify public fixture signatures with installed OpenSSL; no new package dependency |
| PR #17 title used unsupported association scope | Change PR title to allowed iac scope; commit history preserved |
| New module CI injected only aws.project | User-authorized narrow fix in PR #17 injects every declared AWS alias; exact shell-block regression passes; no check removed |

Earlier failures are retained in local delivery logs. A green mock plan is not deployment evidence. A green Infracost job alone is not evidence of zero cost; numerical estimates are not claimed in this report. The inherited pipeline publishes its service result or explicit estimate-unavailable notice to the job summary.

## Independent review

SR1 is the B13 co-owner and appropriate scope/acceptance reviewer; SR2 owns B07/B09 and relevant architecture decisions. Final review/closure follows the human lead or designated independent reviewer in AGENTS.md. No review, release, waiver or approval is invented. Existing long-lived feature branches are preserved at the user's explicit instruction. The review exceeds the approximate 400-line target because complete source, fixtures, negative tests and evidence are included in atomic commits.


[Actual terminal verification excerpts](b05-terminal-evidence.md) accompany this report.
