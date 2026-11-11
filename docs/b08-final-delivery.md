# B08 final plan-only delivery evidence

Refs aroma-pacifico/aroma-pacifico-roadmap#28. Status: **TECHNICALLY COMPLETE FOR PLAN-ONLY DELIVERY**; independent acceptance pending.

## Implementation and B09 contract

One `modules/farm` invocation represents one opaque farm ID, crop and drying logical nodes, two IoT things, two CSR-based certificates, two thing-principal attachments and two policy attachments. The module uses injected aws.project, validates dev/qa/pdn context, constructs stable root-prefixed names, rejects duplicate CSRs after whitespace normalization, and never generates a private key. No physical hardware, firmware or 200-farm inventory is represented.

B09 still has no published ingestion implementation. The existing typed adapter is complete and exercised: `ingestion = { environment, endpoint, policy_name, topic_template }`. `.invalid` endpoints and fixture policy names are synthetic; they are not deployed policies. Policy names reject invalid characters, and the topic contract requires exactly one thing-name placeholder, nonempty ASCII namespace levels and no MQTT wildcards or unknown placeholders.

The complete local workload sample now plans one farm in dev, qa and pdn using the same child logic. The separate `production-template/*.tf.example` contains the full input/CSR/provider/output adapter and future S3 backend, with `REQUIRED_REVIEWED_RELEASE` unchanged because no real tag exists. B09 ingestion remains its owner's story.

## Actual plan inventory

Each row uses Terraform 1.15.8, AWS 6.0.0, `command=plan`, a mock provider, the two public CSR fixtures, expected/actual eight creates, no updates/deletes/replacements, assertion PASS and verifier exit 0. Every graph contains exactly two of each of the four approved IoT resource types.

| Root / run | Environment | Input fixture / farm | Expected creates | Actual creates / updates / deletes | Assertions |
|---|---|---|---:|---|---|
| Child farm_a | qa | tests/farm_unit_test.tftest.hcl; fixture-a | 8 | 8 / 0 / 0 | Exact resources, names, own-role attachments, public CSR, topic/output contract |
| Child farm_b | qa | same native test; fixture-b | 8 | 8 / 0 / 0 | Same logic, distinct farm metadata/names |
| Child dev_isolation | dev | same native test; fixture-a | 8 | 8 / 0 / 0 | Matching names, metadata and synthetic ingestion context |
| Complete sample qa_association | qa | terraform.tfvars; fixture-a | 8 | 8 / 0 / 0 | One child and complete output adapter |
| Complete sample dev_association | dev | sample native override; fixture-b | 8 | 8 / 0 / 0 | Correct node/topic substitution |
| Complete sample pdn_workload_association | pdn | sample native override; fixture-a | 8 | 8 / 0 / 0 | Same workload composition and isolated context |

## Executed verification

```text
terraform fmt -check -recursive: exit 0
child/sample init -backend=false -input=false: exit 0
sample validate: Success! The configuration is valid.
child terraform test: Success! 19 passed, 0 failed.
sample terraform test -var-file=terraform.tfvars: Success! 3 passed, 0 failed.
sample CI-parity terraform test without explicit var-file: Success! 3 passed, 0 failed.
python scripts/verify-farm.py: six exact eight-create graphs and five required-input/type rejections; exit 0
tflint with AWS ruleset 0.44.0: child/sample exit 0
Trivy: 51 successes, 0 failures; exit 0
OpenSSL public CSR fixtures: Certificate request self-signature verify OK (both); exit 0
git diff --check: exit 0
```

Native negatives reject blank farm ID, unsupported environment, cross-environment ingestion/naming, empty/malformed policy, URL-shaped endpoint, MQTT wildcard, missing thing-name placeholder, malformed CSR, duplicate CSR with identical/CRLF/trailing whitespace forms, multi-farm node keys, empty topic levels and unknown topic placeholders. Five additional Python fixtures reject missing ingestion/nodes/endpoint, inventory-valued farm ID and null farm ID.

## Security and limits

Public CSR envelope/distinctness is validated by Terraform; fixture signature correctness is independently checked by OpenSSL. This does not validate every possible submitted CSR cryptographically or prove device possession of its private key. The pinned provider's CSR branch requests a certificate from the supplied public CSR instead of generating a private key. Mock private/public-key outputs are explicitly empty and not exported.

The current provider schema exposes no tags on the four IoT resource types. Desired cost metadata and IoT attributes are not AWS cost tags. SR2 must reconcile PD-071; no extra resources or fake tags are added. Store-and-forward metadata describes QoS 1, PUBACK release and a maximum 24-hour buffer contract; Terraform does not implement firmware, delivery, latency or actual MQTT ingestion. The sample is included in Infracost's inherited configuration, with no unsupported zero-cost claim.

## Acceptance criteria

| Original criterion | Status | Implemented code | Relevant test / plan | Security evidence | Remaining limitation |
|---|---|---|---|---|---|
| The module represents a pattern farm with reusable parameters. | PASS | Singular farm, two typed roles, root-built stable prefix | farm_a/farm_b exact eight-create plans | Distinct public CSR inputs; injected provider | Physical enrollment and private-key possession are not proven |
| The code does not deploy 200 farms or physical hardware. | PASS | Only four IoT resource families; one child invocation | All six graphs contain one farm and two roles | Resource whitelist and no secret/key generation | No hardware or firmware behavior is claimed |
| The module provides connection points for store-and-forward ingestion without modeling firmware. | PASS | Typed B09 adapter, endpoint/topics/certificate and protocol metadata outputs | Own-node substitution and contract assertions | Policy/topic validation; static scan clean | B09 references synthetic; no ingestion or buffering runtime proof |
| The module can be associated with the environment without duplicating logic. | PASS | Complete local workload root and separate release-gated template | Same child plans in dev, qa and pdn; eight creates each | Cross-environment mismatches rejected | Real B09 outputs and reviewed release are future shared-consumption inputs |

## Reproduction and review

Use the approved launcher in isolated validation context without AWS credentials. Initialize child and sample backend-disabled, run native tests, and run `python scripts/verify-farm.py`. The script checks the exact resource family/count, CSR association, one farm per invocation, no state files and required-input rejection. Sample public CSR paths resolve from the checkout. Production template CSR paths must be supplied by the consuming workload root, never by storing private keys.

PR: [modules #3](https://github.com/aroma-pacifico/aroma-pacifico-terraform-modules/pull/3). Keep Draft pending independent review and owner acceptance. No AWS credentials, live ingestion or physical devices are needed to reproduce the delivered plan-only evidence.


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

SR1 @EstebanGZam is the named B13 co-owner and appropriate scope/acceptance reviewer; SR2 @tomoewinds owns B07/B09 and relevant architecture decisions. Final review/closure follows the human lead or designated independent reviewer in AGENTS.md. No review, release, waiver or approval is invented. Existing long-lived feature branches are preserved at the user's explicit instruction. The review exceeds the approximate 400-line target because complete source, fixtures, negative tests and evidence are included in atomic commits.


[Actual terminal verification excerpts](b08-terminal-evidence.md) accompany this report.
