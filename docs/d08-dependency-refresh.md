# B08 dependency and verification refresh

Date: 2026-11-10. Status: PARTIAL; Draft PR required. This refresh supersedes
historical permission and dependency statements in the earlier evidence snapshot.
No AWS credentials, live backend initialization, account plan, deployment,
migration, unlock or Terraform state mutation was used.

## Fresh sources and governance

`gh auth status` succeeds for the JR2 account outside the sandbox. The repository API
confirms `pull: true` and `push: true` on infrastructure, modules and roadmap.
The sandbox's invalid-token diagnostic was an identity/access limitation, not
the current GitHub account status. Branches and all-state PR listings were
checked before publication; neither Terraform repository had a feature branch,
equivalent PR or module release tag at the start of this refresh.

The canonical constitution and git-agent/doc-agent skills, distributed copies,
both CONTRIBUTING guides, Terraform best practices and PC-IAC-001 through 026
were reviewed. No installed Terraform-specific skill was found. Fresh canonical
case extraction read all nine pages. Latest fetched source revisions are:
governance `692e5b2`, architecture `39116e5`, diagrams `1cbfb92`, infrastructure
main `5b0754b`, modules main `8d17017`. Only the corresponding main governance
commit was merged into this feature; previous story history remains intact.
No other feature was merged, rebased or overwritten. The branch predates the
48-hour target and its complete diff exceeds the 400-line target; those
exceptions remain visible for review, rather than rewriting existing work.

The dependency audit used fresh issue bodies, every available comment, issue
timelines, all-state PR lists/files and fetched main trees, rather than issue
closure alone. B01 (aroma-pacifico/aroma-pacifico-roadmap#21), B04 (aroma-pacifico/aroma-pacifico-roadmap#24), B07 (aroma-pacifico/aroma-pacifico-roadmap#27) and B09 (aroma-pacifico/aroma-pacifico-roadmap#29) are Open with no Terraform
implementation or linked implementation PR found. A04 (aroma-pacifico/aroma-pacifico-roadmap#4) has accepted ADR-003
in architecture PR #10; A11 (aroma-pacifico/aroma-pacifico-roadmap#11) has the merged center design in PR #23; A10 (aroma-pacifico/aroma-pacifico-roadmap#10)
has the merged connectivity design in PR #21. These three Closed dependencies
are verified at the design boundary, not deployed infrastructure.

Architecture PR #38 adds the 100-hour plan: ASM-212 separates module work from
root wiring; ASM-213 assigns state bucket/KMS ownership to B02. PD-210 still
asks the lead to reconcile roadmap dependency lists. PR #39 adds observability
and dashboards without publishing B04/B09 module outputs or resolving PD-071.
Existing addressing and ingestion contracts were not replaced. New diagrams
cover addressing, connectivity, farm monitoring, security and pipelines; the
complete drawing (diagrams PR #3) and center drawing (PR #10) remain Open and
were not adopted as approved changes. No diagrams or teammate issues were edited.

## Validation scope

Terraform 1.15.8 meets the approved >=1.14 floor; B01 still has not selected the
exact CI patch. TFLint 0.65.0 used bundled Terraform rules only, with its official
release SHA-256 verified. Trivy 0.76.2 used the existing cached policy bundle
with `--skip-check-update`; no claim of freshly updated scanner checks is made.
Checkov was unavailable; Trivy supplies the alternative scan. The managed
Terraform launcher used `AUTODEV_TF_CONTEXT=validation` and backend-disabled
initialization. Provider caching occurred locally; no AWS API was called.
Static scanner success on a partial graph does not verify missing controls.

All three branches passed format and Git whitespace checks. Changed files and
historical story revisions were checked for common credentials, private keys,
account-qualified ARN literals and state artifacts. No findings were observed;
this pattern review is not a comprehensive dedicated secret scan.

## B08 findings and changes

Refs aroma-pacifico/aroma-pacifico-roadmap#28.
One invocation still represents one opaque farm ID with exactly crop/drying
logical roles: two IoT things, two CSR certificates, two thing-principal and two
policy attachments. It creates neither physical equipment nor firmware, keys,
farm networks, an ingestion service or a 200-farm inventory. The child declares
aws.project; the offline sample injects aws.principal and pins AWS ~>6.0.0 with
the existing 6.0.0 lock. No provider version or resource address changed.

The new duplicate-CSR regression failed against the old raw-string comparison:
15 passed/1 failed because a trailing-whitespace variant was accepted. Normalize
PEM whitespace for comparison only; preserve the public request passed to AWS.
Sixteen module scenarios now pass, including line-ending and whitespace cases.
This does not verify CSR signatures, distinct device public keys or enrollment.
Real enrollment must verify them outside Terraform; no private key is generated.

B09 still publishes no reviewed endpoint/policy/topic output contract. The
existing ingestion object is an explicitly provisional adapter, constrained to
the same environment and one own-thing placeholder without MQTT wildcards.
No production namespace was invented. Store-and-forward outputs state A10's
connection requirements; they do not implement a buffer, persistence or latency.

The installed AWS 6.0.0 schema was inspected afresh: none of the four approved
resource types exposes a tags argument. FarmId/Environment/NodeRole attributes
and desired_cost_tags are not billing tags. New observability design does not
resolve PD-071. Farm enrollment format/registry linkage remains owner-supplied.

| Acceptance criterion | Status | Evidence and limit |
|---|---|---|
| Reusable farm parameters | PASS | Two farm identities tested separately through one module. |
| No 200 farms or physical hardware | PASS | Each valid mocked graph has exactly eight approved IoT identity creates. |
| Store-and-forward connection points without firmware | PASS | Input/endpoint/topic/policy contracts and outputs tested; no delivery guarantee. |
| Associate with environment without duplicated logic | PARTIAL | QA/dev sample reuse passes; actual private workload root/released source/B09 integration absent. |

Sixteen child and two sample-root native scenarios pass. Five additional
mandatory-input/type rejection fixtures pass. Five valid mocked graphs each
contain one farm/two roles/eight creates/zero destroys/zero replacements. Root
validate and both TFLint runs pass; Trivy reports 51 successes/zero failures.
Direct child-as-root validation is inappropriate without its injected alias;
the consuming root validates the child. No provider was added to hide that.
No SemVer tags exist. Root integration must await a real reviewed release and
B01/B02/B03/B04 foundations/B09 references; no unpublished feature branch is
used as a shared-environment dependency. PD-019/071 remain Open.

## Executed command evidence

All commands below exited 0. Run from this repository root; tool paths are shortened for portability.

```text
terraform fmt -check -recursive
terraform -chdir=modules/farm init -backend=false -input=false -no-color
terraform -chdir=modules/farm test -no-color
tflint.exe --chdir=modules/farm --format=compact
terraform -chdir=modules/farm/sample init -backend=false -input=false -no-color -lockfile=readonly
terraform -chdir=modules/farm/sample validate -no-color
terraform -chdir=modules/farm/sample test -no-color -var-file=terraform.tfvars
tflint.exe --chdir=modules/farm/sample --format=compact
python scripts/verify-farm.py
git diff --check
git diff --check --cached
git diff --check origin/main...HEAD
trivy config --skip-check-update --misconfig-scanners terraform --exit-code 1 [story target and synthetic tfvars]
```

Actual custom-verifier output:

```text
PASS farm_a: one farm, two node roles, eight mocked creates, zero destroys/replacements
PASS farm_b: one farm, two node roles, eight mocked creates, zero destroys/replacements
PASS dev_isolation: one farm, two node roles, eight mocked creates, zero destroys/replacements
PASS 16 native scenarios in modules/farm
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

EXIT 0
```

## Review, risks and next action

Keep the roadmap issue Open and the PR Draft. No complete story or cloud
integration is claimed. Review atomic commits separately. A reviewed code
revert is the rollback; no cloud rollback or state restoration exists here.
Changes to shared backend/module interfaces require a new review and repeat
of affected checks. Actual publication links/status and related Draft PRs
are recorded in the PR and the new roadmap progress comment.

## Published review package

The assigned branch `feat/28-pattern-farm` was pushed successfully without force.
[B08 Draft PR](https://github.com/aroma-pacifico/aroma-pacifico-terraform-modules/pull/3) is Open, targets main, and remains Draft.
Its three existing GitHub convention checks passed; they do not run Terraform
or replace the recorded local checks. Related Draft PRs: [B02](https://github.com/aroma-pacifico/aroma-pacifico-infrastructure/pull/3); [B05](https://github.com/aroma-pacifico/aroma-pacifico-infrastructure/pull/4); [B08](https://github.com/aroma-pacifico/aroma-pacifico-terraform-modules/pull/3).
The roadmap issue remains Open. No PR was merged and no release tag was created.
