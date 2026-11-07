# D08 / B08 implementation evidence

Date: 2026-11-07. Owner: JR2. Status: module verified offline; runtime integration partial.
Refs [aroma-pacifico/aroma-pacifico-roadmap#28](https://github.com/aroma-pacifico/aroma-pacifico-roadmap/issues/28).

## Governance and requirements

The canonical `aroma-pacifico-ai-agents/AGENTS.md` was read; applicable local
copies are identical (SHA-256
`21BB66D8A28C2668D15FF617406B797D9316F3BC045A0F01905681FF39DDE229`).
The git-agent and doc-agent skills were applied. The diagram-agent skill was
reviewed; no diagram was authored. No Terraform-specific installed skill or
Terraform MCP schema tool was available. Local provider schema inspection was
used instead of guessing resource arguments.

Reviewed standards include Terraform best practices and relevant PC-IAC rules
for structure, inputs, naming, tags, aliases, versions, outputs, state, locals,
multiplicity, module consumption, secrets, testing, security, domain boundaries,
root processing and samples; also Git/documentation standards and both Terraform
repositories' CONTRIBUTING guides. The constitution is unchanged.

The original nine-page academic PDF was reviewed through its existing extraction,
then freshly extracted with pypdf 7.0.0. The two complete extractions matched
exactly. Only one pattern farm is coded; the physical pilot inventory and
firmware are excluded by the case. Architecture revision is
`3f704edde46c433bee0284d58838c23310e089a0`.

| Architecture source | Applied boundary |
|---|---|
| ADR-001 | Environment/account separation and root Region selection |
| ADR-003, device identity and drain sections | IoT things, CSR registration, certificate attachment; ingestion policy owned by B09 |
| A10 `docs/connectivity.md`, sections 4.1 to 4.4 | Crop/drying roles, public IoT path, TLS/QoS 1, 24-hour buffer and drain requirements |
| A09 `docs/security-and-identity.md`, section 6 | Per-node certificate, attached thing/client identity, own-topic publish policy |
| A07 `docs/addressing-plan.md`, section 5 | Farm growth adds identities, not VPC addresses/routes |
| A08 `docs/landing-zone.md`, section 5.1 | FarmId/CostCenter metadata and unresolved PD-071 |
| A14 farm-monitoring design; A13 data-path document/XML | Reading metadata, history/idempotency and bypass of center/VPC networking |
| A19 `docs/architecture.md`, section 14 | D08 documented equivalent: reusable farm identity pattern |

No D08/complete drawing exists in the reviewed local/remote diagram inventory.
The documented D08 mapping and A13 telemetry source are available; no visual
D08 conformance claim is made. Existing Proposed metadata is not changed.

## Actual story and dependencies

The exact issue is `[B08] Code the reusable farm module`, owner JR2, assigned
to the authenticated contributor, estimate 8 h, Open. Its objective and four
acceptance criteria exactly match the request. It has no scope discrepancy.

| Dependency | Verified status and implementation |
|---|---|
| [B04 #24](https://github.com/aroma-pacifico/aroma-pacifico-roadmap/issues/24), `[B04] Code the network module for the pattern environment` | Open; JR1; assigned kvjc; 10 h; blocked by B02/B03/A07. No implementation PR or reusable network outputs found in either Terraform repository or issue timeline. |
| [A10 #10](https://github.com/aroma-pacifico/aroma-pacifico-roadmap/issues/10), `[A10] Design end-to-end connectivity, including the no-signal case` | Closed; SR1 / JR1; no assignee. [Architecture PR #21](https://github.com/aroma-pacifico/aroma-pacifico-architecture/pull/21) merged; supersedes closed PR #19. Design is available. |

B04 requires the seven subnet roles, distinct environment blocks, reusable
association outputs and a non-overlap plan. A10 requires all field/center/port
flows, the farm's 24-hour buffer/drain, the under-five-minute alert design target,
offline transporter events/positions and independence from obsolete mobile
generations. A10's closed status is supported by its merged design; its alert
latency is not measured delivery evidence.

The farm uses public IoT ingress, so no B04 VPC/subnet/VPN input is fabricated.
B04 remains a root-platform integration dependency, not a blocker to the isolated
identity module tests. B09 owns the actual ingestion contract and policy. These
owners' stories and statuses were not changed.

## Implemented module and scope

Only `aroma-pacifico-terraform-modules` changes. One `modules/farm` invocation
accepts one opaque `farm_id`, root governance/prefix, exactly two public CSRs
under crop/drying keys, and same-environment ingestion references. It plans:

| Resource type | Instances per valid invocation |
|---|---:|
| `aws_iot_thing` | 2 |
| `aws_iot_certificate` | 2 |
| `aws_iot_thing_principal_attachment` | 2 |
| `aws_iot_policy_attachment` | 2 |

The things are logical registry identities. There is no physical procurement,
firmware/OS installation, farm inventory, network, compute, policy document,
queue, database or ingestion application. `for_each` ranges only over the
validated crop/drying map, never the pilot farms.

The child declares `aws.project`, never configures a provider/backend, and
requires Terraform >= 1.14.0 / AWS >= 6.0.0. The sample root pins AWS ~> 6.0.0
and commits its generated lockfile. The child lockfile is ignored. The sample
calls one child through `../`, the permitted offline development method; no
shared-environment local source, fabricated module tag or infrastructure root
change is introduced. B02/B05 histories remain untouched.

The root builds names; the child appends only the node-role suffix. Ingestion
topic rendering uses an externally supplied template with one `{thing_name}`
placeholder and no MQTT wildcards. This is an adapter awaiting B09 review,
not a selected production topic namespace. Endpoint and environment checks
validate configuration, not account ownership or service existence.

`node_names`, `certificate_arns`, `ingestion_endpoint` and `telemetry_topics`
are granular integration outputs. `store_and_forward_contract` documents A10
requirements; it does not implement message transport, buffering, retry,
persistence, idempotency or latency guarantees. Metadata labels are semantic,
not a new payload schema. Department/location metadata is not required by the
approved identity boundary and remains in the platform registry.

The pinned provider schema and certificate implementation were inspected.
Supplying CSR selects `CreateCertificateFromCsr`; key generation occurs only
on the separate no-CSR branch. The module always requires CSR and exports no
keys or certificate PEM. Test CSRs are synthetic public requests; their temporary
generation keys were deleted outside the repository. Both public CSR signatures
were verified with OpenSSL.

No tag argument exists on these four provider resource types. FarmId,
Environment and NodeRole registry attributes are not AWS cost tags.
`desired_cost_tags` exposes intent only; PD-071 remains unresolved. No extra
resource was added to conceal this limitation. See the [decision register](decision-log.md).

## Actual verification

Terraform 1.15.8, AWS provider 6.0.0, Python 3.13, TFLint 0.65.0 and Trivy 0.76.2.
The provider was downloaded from the registry and reported signed by HashiCorp.
Subsequent offline mirror installs reported unauthenticated local installation;
the sample uses the original registry lock/checksums. No signature claim is made
for the local mirror itself. Native tests replace providers with mocks.

```text
terraform fmt -check -recursive
Exit 0; no output.
terraform '-chdir=.local/schema' init -backend=false -input=false -no-color
Installed hashicorp/aws v6.0.0 (signed by HashiCorp).
$providerMirror = (Resolve-Path '.local/schema/.terraform/providers').Path
terraform -chdir=modules/farm init -backend=false -input=false -no-color "-plugin-dir=$providerMirror"
Terraform has been successfully initialized!
terraform -chdir=modules/farm/sample init -backend=false -input=false -no-color -lockfile=readonly "-plugin-dir=$providerMirror"
Terraform has been successfully initialized!
terraform -chdir=modules/farm/sample validate -no-color
Success! The configuration is valid.
terraform -chdir=modules/farm test -no-color
Success! 14 passed, 0 failed.
terraform -chdir=modules/farm/sample test '-var-file=terraform.tfvars' -no-color
Success! 2 passed, 0 failed.
python -u scripts/verify-farm.py
PASS farm_a: one farm, two node roles, eight mocked creates, zero destroys/replacements
PASS farm_b: one farm, two node roles, eight mocked creates, zero destroys/replacements
PASS dev_isolation: one farm, two node roles, eight mocked creates, zero destroys/replacements
PASS 14 native scenarios in modules/farm
PASS qa_association: one farm, two node roles, eight mocked creates, zero destroys/replacements
PASS dev_association: one farm, two node roles, eight mocked creates, zero destroys/replacements
PASS 2 native scenarios in modules/farm/sample
PASS missing_ingestion: rejected (No value for required variable)
PASS missing_nodes: rejected (No value for required variable)
PASS missing_endpoint_reference: rejected (Invalid value for input variable)
PASS farm_inventory_as_identifier: rejected (Invalid value for input variable)
PASS null_farm_identifier: rejected (Required variable not set)
PASS scope: only IoT cloud identities, no hardware/network/compute, no 200-farm graph, no state files
PARTIAL runtime integration: B04/root foundations, B09 references, release and PD-071 remain pending
```

| Requested coverage | Actual evidence |
|---|---|
| One farm and another farm | Two child scenarios with different synthetic identifiers/prefixes; two identities/eight resources each |
| Invalid identifiers/environment | Blank/null/list farm inputs and unsupported environment rejected |
| Location/department consistency | Not applicable: no such input or association is required by this identity boundary; no invented geography validation |
| Missing ingestion references | Missing object, missing endpoint and blank policy rejected |
| Invalid ingestion configuration | URI endpoint, wildcard/missing-own-node topic template, cross-environment references rejected |
| No 200-farm loop or hardware | Five valid JSON resource graphs checked against a four-type whitelist, each exactly two roles/eight creates |
| Root association and isolation | QA/dev roots invoke the same child; environment-specific names, metadata, endpoint and topics asserted |
| Connection outputs | Names, certificate references, endpoint, topics and A10 contract asserted; attachment targets match corresponding certificates |

TFLint ran on both `modules/farm` and `modules/farm/sample` with exit 0 and no
findings (bundled Terraform rules). Trivy scanned the consuming sample and child
configuration with the synthetic tfvars after successfully downloading its checks:

```text
trivy config --cache-dir .local/trivy-cache --disable-telemetry --misconfig-scanners terraform --tf-vars modules/farm/sample/terraform.tfvars --exit-code 1 --format json --output .local/d08-trivy-final.json --timeout 45s modules/farm/sample
Exit 0. Detected config files: 1. MisconfSummary: Successes 51, Failures 0.
openssl req -in modules/farm/tests/fixtures/crop.csr -verify -noout
Certificate request self-signature verify OK
openssl req -in modules/farm/tests/fixtures/drying.csr -verify -noout
Certificate request self-signature verify OK
git diff --check
Exit 0; no output.
```

The scanner result is static coverage, not proof of runtime policy, encryption,
delivery, account isolation or edge behavior. Checkov was not available; Trivy
fulfills the alternative scanner check. No actual AWS account plan was run.
All eight-create graphs are mocked plan evidence; no AWS resources were created.

Direct `terraform -chdir=modules/farm validate` reports `Provider configuration
not present` for aws.project, because the child is not a standalone root.
Validation through the sample succeeds and validates the child's configuration.
Do not add a provider to the child or mutate state to address that diagnostic.
Other initial failures and corrections are recorded in the [troubleshooting log](troubleshooting-log.md).

## Acceptance status and remaining work

| Criterion | Status | Evidence/limit |
|---|---|---|
| Represents a pattern farm with reusable parameters | PASS | Typed singular farm, two roles, distinct reusable farm scenarios and eight-resource plans |
| Does not deploy 200 farms or physical hardware | PASS | Whitelisted mocked graphs and restricted role map; no deployment command executed |
| Provides store-and-forward connection points without firmware | PASS | Validated destination/policy inputs, identity/topic outputs and documented A10 contract; no delivery guarantee claimed |
| Can associate with the environment without duplicated logic | PARTIAL | QA/dev sample composition proven; released-module and actual infrastructure-root integration remain pending |

The missing actual root foundations/ingestion references, module release,
PD-071 resolution, and approved executable QA plan evidence prevent completion.
PD-019 remains with its owners. The next account-plan command belongs in the
integrated private workload root, after verified backend and identity setup:
`terraform -chdir=stacks/workload plan -input=false -var-file=qa.tfvars -out=qa.tfplan`.
That is a future command, not executed evidence; neither its inputs nor the
deployable root exist in this change. No apply/destroy/unlock/migration is allowed.

## Git/publication and rollback

The feature branch is `feat/28-pattern-farm`, based on modules origin/main
`6445cd0`. Both existing B02/B05 infrastructure branch tips were recorded
and confirmed unchanged; private branch hashes are retained in local evidence.
No infrastructure branch, code or history was modified.

GitHub login succeeded, but both Terraform repositories report `pull: true`,
`push: false`. No D08 push was attempted after that permission check, and no
PR exists. The historical D05 rejection was HTTP 403, `Write access to repository
not granted`; access has not been restored. A complete local Draft PR body is
prepared using the repository template. No credential/remote workaround is used.

The authorized [B08 progress comment and sanitized evidence snapshot](https://github.com/aroma-pacifico/aroma-pacifico-roadmap/issues/28#issuecomment-6713913430)
were published successfully. This is the available remote evidence link; the
module code and repository evidence document remain local pending push access.

The diff exceeds the approximate 400-line review target because mandatory module
layout, public CSR fixtures, explicit positive/negative tests, sample composition
and reproducible evidence are included. Core resource logic is 34 lines. Review
the atomic commits separately. Rollback is to revert the feature commits; no
cloud rollback is needed because nothing was deployed. Keep B08 Open and any
eventual PR Draft until integration and required governance decisions are resolved.
