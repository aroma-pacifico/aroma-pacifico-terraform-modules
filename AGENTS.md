# AGENTS.md — Aroma Pacífico Engineering Constitution

**Normative for every human and every AI agent that writes code, infrastructure, manifests or documentation in the Aroma Pacífico project.**

Adapted from SINTRATEL and FrioAndes reference standards.

---

## 0. Scope, Precedence, and Distribution

This file is the single normative constitution for how work is produced in this project. It is not advisory. Where it conflicts with habit, memory, a tutorial, or a model's prior training, **this file wins**.

**Precedence, highest first:**

1. An explicit instruction from the user in the current conversation
2. This file (`AGENTS.md`)
3. The `standards/` files (`standards/terraform-iac-best-practices.md`, `standards/iac-rules/`, `standards/documentation.md`, `standards/diagrams.md`, `standards/git-workflow.md`)
4. Repository-local `CONTRIBUTING.md`
5. Existing conventions visible in surrounding code
6. General best practice

**Distribution.** `aroma-pacifico-ai-agents` is the canonical home of `AGENTS.md` and related engineering standards. It is copied verbatim across delivery repositories and is never edited in a copy. Change it here, then run the sync script (`scripts/sync-rules.sh`). Agents and developers operating in this repository or in linked project repositories must adhere to these rules. `CLAUDE.md` imports this file on its first line (`@AGENTS.md`), and `GEMINI.md` points Gemini and Antigravity to it.

**Maintenance.** Treat this file as a *failure log, not a wishlist*. When an agent makes the same mistake twice, this file is missing a line. Add the line.

---

## 1. Prime Directives

1. **English only.** Code, comments, documentation, commits, PR titles and bodies, branch names, file names, directory names. No exceptions.
2. **Zero emojis.** Strictly prohibited across all commits, branches, PRs, documentation, code, and agent responses.
3. **Academic delivery: plan-only.** Deliver design, modular Terraform, cost evidence, and a presentation. As confirmed by the faculty advisor, the project stops at `terraform plan`. Never run `terraform apply`/`destroy`, never deploy, never register providers, and never create live cloud resources. Pipelines must still prove that code would work if deployed: formatting, validation, tests, security scans, and a reviewable plan.
4. **Requirements source.** `docs/case/case-statement.pdf` is the sole source of requirements. Never invent a value, measurement, approval, or rehearsal result. Every assumption not in the case statement must be registered in the decision log (`docs/decision-log.md`) with a unique ID.
5. **Trunk-based development.** Direct commits to `main` are prohibited. Work on short-lived branches (`<type>/<issue-number>-<kebab-slug>`) under 48 hours and under 400 lines.
6. **Atomic Conventional Commits.** Every commit must follow `<type>(<scope>): <lowercase imperative subject>` with a mandatory `Refs #<issue>` footer. Commit incrementally as you go.
7. **Agent publishing boundary.** Agents commit locally and may push only their own assigned feature branch to open a PR to `main`. Agents never push to `main`, never force-push, and never create repositories. Implementer agents never merge. The designated reviewer agent, which runs on a different AI provider than the implementer, reviews the pull request and squash-merges it when it approves and every check is green, following the review protocol. A pull request that needs a business decision, weakens CI checks or deletes out-of-scope content goes to the human lead instead. The reviewer may delete the merged head branch. The human lead can still review or merge at any time.
8. **Repository model.** Concern separation across dedicated organization repositories. Terraform code (`.tf`) belongs strictly in `aroma-pacifico-terraform-modules` and `aroma-pacifico-infrastructure`; no `.tf` files in any other repository.
9. **Binding IaC rules.** The 28 reference module rules in `standards/iac-rules/` (`pc-iac-001.md` through `pc-iac-028.md`) and `standards/terraform-iac-best-practices.md` are binding for all Terraform work. Renaming a resource requires a `moved` block. Automated Infracost cost estimation in CI/CD pipelines is mandatory per `pc-iac-027.md`, and credential-free plan execution against the Floci AWS emulator is mandatory per `pc-iac-028.md`.
10. **Show your verification.** "Done" requires running formatting, validation, and verification checks and showing the actual terminal output. Never state something works without showing the verification evidence.

---

## 2. Language and Typography

**English, everywhere, without exception.**

| Surface | Rule |
|---|---|
| Source code, identifiers | English |
| Comments and docstrings | English |
| Documentation, README, ADRs | English |
| File and directory names | English, `kebab-case` for files, `kebab-case` for directories |
| Commit messages | English, imperative mood |
| Branch names | English |
| PR titles and bodies | English |
| Terraform variables, resources, outputs | English, `snake_case` |
| Issue and Kanban card titles | English |

No accents, no Spanish words, no mixed-language identifiers.

### Strict Zero-Emoji Mandate
Emojis are strictly prohibited across all surfaces. All communication and artifacts must use clean, professional plain text.
- Replace status icons with explicit plain text words: use `SUCCESS` instead of checkmarks, `WARNING` instead of caution triangles, and `ERROR` instead of crosses.

---

## 3. Requirements, Assumptions, and Truth

- **Single source of truth**: `docs/case/case-statement.pdf` is the only source of project requirements.
- **Decision and Assumption Log**: If a parameter, dimension, retention period, or design choice is not specified in `docs/case/case-statement.pdf`, it cannot be silently invented. It must be logged in the project decision log (`docs/decision-log.md`, created by task A01) with a unique ID: `ASM-NNN` for assumptions, `ADR-NNN` for architecture decision records (stored in `docs/adr/`) and `PD-NNN` for pending decisions.
- **Never invent evidence**: Do not invent performance measurements, latency metrics, failover timings, human approvals, or rehearsal results. Label latency, failover, rollout, and recovery metrics as targets or future tests.

---

## 4. Academic Delivery Model

This project is an academic DevOps challenge representing the 2026 update of a coffee traceability pilot across Cauca, Huila, and Tolima.
- **Scope**: High-level design, reusable modular Terraform, cost forecasts/evidence, and presentation materials.
- **Plan-only boundary**: As confirmed by the faculty advisor, the project stops at `terraform plan`. Nothing is deployed and no cloud resource is created; `terraform apply` and `terraform destroy` are never run.
- **Pipeline proof of deployability**: Pipelines must nonetheless prove that the code would work if deployed, executing formatting checks, schema validation (`terraform validate`), linting, security scans, native plan-mode unit tests (`.tftest.hcl`), reviewable speculative plans, and automated Infracost cost estimates.
- **Prohibited cloud mutations**:
  - Never run `terraform apply` or `terraform destroy`
  - Never run `kubectl apply`, `helm install`, or cloud resource creation commands
  - Never register cloud providers or create remote infrastructure
  - Never execute live deployment pipelines

---

## 5. Organization Repository Model

The `aroma-pacifico` GitHub organization has one repository per concern:

| Repository | Visibility | Holds |
|---|---|---|
| `aroma-pacifico-roadmap` | Private | Issues, milestones, labels only (no rules, no code) |
| `aroma-pacifico-ai-agents` | Private | Canonical rules, standards, skills and the sync script |
| `aroma-pacifico-architecture` | Private | Case statement, decision log, ADRs, design documents, plan, observability, release notes, costs |
| `aroma-pacifico-diagrams` | Private | Diagram sources and SVG/PNG exports, boxes D01-D13 |
| `aroma-pacifico-terraform-modules` | **Public** | Reusable Terraform reference modules, versioned by git tag (pc-iac-015) |
| `aroma-pacifico-infrastructure` | Private | Terraform root stack of the pattern environment, remote state, variables, plan-only CI/CD |
| `aroma-pacifico-design-system` | Private | Design system of the three applications |
| `aroma-pacifico-presentation` | Private | Final presentation and defense script |

Every issue lives in `aroma-pacifico/aroma-pacifico-roadmap`. Reference issues as `aroma-pacifico/aroma-pacifico-roadmap#<n>`, never as a bare `#<n>`.

Terraform `.tf` files belong strictly in the two Terraform repositories (`aroma-pacifico-terraform-modules` and `aroma-pacifico-infrastructure`). No `.tf` files are permitted in any other repository.

### 5.1 Public Repository Hygiene

`aroma-pacifico-terraform-modules` is **public** by design, allowing `terraform init` to reference modules without credentials while preserving a zero-static-keys security posture.

In `aroma-pacifico-terraform-modules`, never write an account identifier, account-qualified ARN, internal hostname, real endpoint, credential, named principal, or client data, because git history is public too.

**Git history is public too.** A leaked identifier, secret, or internal domain requires git history rewriting, not a follow-up commit. Pre-commit reviews and local verification must ensure no confidential identifiers enter the public repository.

### 5.2 Modules and Stacks

The two Terraform repositories have strictly separated roles:

| Dimension | `aroma-pacifico-terraform-modules` | `aroma-pacifico-infrastructure` |
|---|---|---|
| Holds | Reusable reference modules | Root modules (stacks) |
| Declares `provider` / `backend` | Never | Always |
| Contains an account identifier | Never | Yes, in stack configuration |
| Versioned by | Git tags (`v1.2.0`) | Not versioned; represents the pattern state |
| Changed by | A module improvement | Wiring, or a version bump |

**Separation of concerns:**
- Never add a resource to a stack that belongs in a reference module.
- Never hardcode a project-specific name inside a reference module. A module that names its own resources `aroma-*` is not reusable.
- Reference modules must take a `name_prefix` input variable instead.
- Root stacks wire reference modules and inject governance variables (`locals.tf`).

### 5.3 Rules Distribution and Canonical Governance

The canonical copy of `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, engineering standards (`standards/`), agent skills (`.agents/skills/`), and workflow conventions lives in `aroma-pacifico-ai-agents`.

- **Verbatim synchronization**: Downstream delivery repositories receive verbatim copies of the distributed rule set.
- **No local edits**: Rules, skills, and standards must never be edited directly in downstream repositories.
- **Sync workflow**: Make changes in `aroma-pacifico-ai-agents`, commit and merge them through PR, then execute `scripts/sync-rules.sh apply <repo>` to synchronize the target repositories.

---

## 6. Source Control Architecture (Trunk-Based Development)

### 6.1 Trunk Stability
- `main` is protected and always in a releasable state.
- Direct commits to `main` are strictly forbidden.

### 6.2 Short-Lived Branches
- Every branch branches off `main` and merges back into `main`.
- Naming convention: `<type>/<issue-number>-<kebab-slug>` (e.g. `feat/12-telemetry-ingestion`, `chore/0-bootstrap-agent-rules`).
- Valid types: `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.
- Branch lifespan: Maximum 48 hours. Target PR size: under 400 lines.

### 6.3 Incremental Atomic Commits
- Commit changes incrementally as each logical unit of work is completed and verified.
- Do not batch all edits into a single end-of-session commit.

### 6.4 Conventional Commits
```text
<type>(<scope>): <lowercase imperative subject (max 72 chars, NO EMOJIS)>

[optional body explaining why, wrapped at 72 chars]

Refs #<issue-number>
```
- Imperative mood, lowercase start, no trailing period, no emojis.
- Body explains the rationale and trade-offs.
- `Refs aroma-pacifico/aroma-pacifico-roadmap#<issue-number>` footer is mandatory. Issues live in the roadmap repository, so always use the full cross-repository reference; a bare `#<n>` points at the wrong repository.
- No tool attribution: no `Co-Authored-By` trailer for an AI tool, no `Generated with` line, no session URL, and no notes about how the content was produced, in commits or PR bodies. `.claude/settings.json` suppresses Claude Code attribution; do not reintroduce it by hand.

### 6.5 Agent Publishing Model
- **Agents commit locally**: Local commits are expected as work progresses.
- **Feature branch push**: Agents may push only their own assigned feature branch (`<type>/<issue>-<slug>`) to the remote repository.
- **Pull Request creation**: Agents may open a Pull Request targeting `main`.
- **Prohibited agent actions**: Agents must never push directly to `main`, never force-push (`git push --force`), and never create repositories. Implementer agents never merge.
- **Review and merge**: The designated reviewer agent, which runs on a different AI provider than the implementer, reviews the pull request and squash-merges it when it approves and every check is green, following the review protocol. A pull request that needs a business decision, weakens CI checks or deletes out-of-scope content goes to the human lead instead. The reviewer may delete the merged head branch. The human lead can still review or merge at any time.

---

## 7. Pull Requests

### Title
The PR title must be a valid Conventional Commit header (max 72 characters, no emojis), because repository squash-merges make the PR title the commit subject on `main`.

### Body
Use `.github/pull_request_template.md`:
1. What changed and why (2-3 concise sentences).
2. Issue traceability: `Closes #<issue>` or `Refs #<issue>`.
3. Acceptance criteria addressed (quoted from the issue with satisfaction notes).
4. Verification evidence (actual terminal commands run and output shown).
5. Terraform plan output (if applicable, with destroys/replacements called out).
6. Risk and rollback considerations.

---

## 8. Terraform and Infrastructure as Code

Detailed standards live in `standards/terraform-iac-best-practices.md` and `standards/iac-rules/`.
The 28 `pc-iac` rules (`standards/iac-rules/pc-iac-001.md` through `pc-iac-028.md`) are binding for every Terraform change.

### Key Enforceable Rules:
- **Reference modules**: Follow the mandatory layout defined in `pc-iac-001.md` (`main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `README.md`).
- **No provider or backend blocks in child modules**: Child modules must remain pure and reusable (`pc-iac-005.md`).
- **Variables and outputs**: Every variable must declare `type` and `description` (`pc-iac-002.md`). Every output must declare `description` (`pc-iac-007.md`). No hardcoded environment-specific defaults.
- **Multiplicity**: Use `for_each` for multiple resource instances; use `count` only for boolean enabling (`count = var.enabled ? 1 : 0`) (`pc-iac-010.md`).
- **Version constraints**: Minimum Terraform core with `>=` (for example `>= 1.14.0`). Providers use a strict `~>` range in root stacks and a compatible `>=` minimum in reference modules (`pc-iac-006.md`). Scoped `.terraform.lock.hcl` committed in root stacks only.
- **Remote state**: Remote backend in S3 with encryption, versioning, and state locking (`pc-iac-008.md`). Strictly no local state.
- **Refactoring**: Renaming or moving a resource address requires a `moved` block. Never rename in place without `moved` (`standards/terraform-iac-best-practices.md` §12).
- **Secrets**: Mark secret variables with `sensitive = true` (`pc-iac-016.md`). Never commit plaintext secrets.
- **Domain separation**: Separate networking, compute, security, and data into distinct lifecycle domains (`pc-iac-022.md`).
- **Testing**: Plan-mode unit tests (`.tftest.hcl`) for reference modules (`pc-iac-018.md`).
- **Automated cost estimation (`pc-iac-027.md`)**: Every IaC pipeline (PR CI and CD promotion with production approval) estimates monthly cost with Infracost CLI v2. Publishes before, after, and delta breakdowns for each root in the job summary, and production approvals display cost next to the plan. Uses secret `INFRACOST_CLI_TOKEN` passed as `INFRACOST_CLI_AUTHENTICATION_TOKEN`, with variables `INFRACOST_ORG=aroma-pacifico` and `INFRACOST_METADATA_EGRESS_APPROVED=true`. Legacy `ico-` keys are rejected. Needs no cloud credentials; missing token outputs "estimate unavailable". Checksum-pinned CLI and SHA-pinned actions. Slack notifications are not required.
- **AWS emulation with Floci (`pc-iac-028.md`)**: The faculty advisor accepted Floci as the plan target in lieu of an AWS account. Pinned image digest `floci/floci@sha256:5ee85db604c4aa74ac76e07ea5cc83086f37bb472bf3dbb97e34019e48efae9c` (Floci 2.4.0). Standard environment `AWS_ENDPOINT_URL=http://localhost:4566`, `AWS_ACCESS_KEY_ID=test`, `AWS_SECRET_ACCESS_KEY=test`, `AWS_REGION=us-east-1`. Zero Terraform code modifications required (honored natively by AWS provider v6). Executed in local Docker or CI service container with `TF_PLUGIN_CACHE_DIR` caching. S3 remote-state evidence initialized via `aws s3 mb` against Floci and dynamic `-backend-config` flags (`use_path_style=true`, `use_lockfile=true`). Plan-only boundary applies strictly; `apply` and `destroy` are forbidden everywhere.
- **Plan-only scope and pipeline proof**: As confirmed by the professor, the project stops at `terraform plan`. Nothing is deployed and no cloud resource is created; `apply` and `destroy` are never run. Pipelines prove code correctness via formatting, validation, tests (`.tftest.hcl`), security scans, and reviewable speculative plans.
- **Identity separation**: Agents operate with plan-only identity; apply is strictly prohibited (§4).

---

## 9. Documentation and Diagram Standards

- **Documentation**: Follow `standards/documentation.md`. Write explanatory prose and Markdown tables over long bulleted lists. Maintain dynamic README and directory tree accuracy. Record friction in `docs/troubleshooting-log.md`.
- **Diagrams**: Follow `standards/diagrams.md`.
  - Canonical format: Uncompressed UTF-8 Draw.io XML (`.drawio`) is preferred; Mermaid is accepted.
  - Required exports: Editable SVG (primary publication) and PNG (preview), committed atomically with the source.
  - Verification: Every diagram must undergo an individual semantic check, visible render, and inspection at actual publication size. Parser success is not visual approval.
  - Native official vendor libraries (AWS/cloud native); no generic shapes where official icons exist; no emojis.

---

## 10. Definition of Done

A task is not done until every applicable criterion is satisfied and verification evidence is shown:

**Every Change:**
- [ ] English throughout (code, comments, documentation, commit messages, PR).
- [ ] Zero emojis across all files, commits, PRs, and messages.
- [ ] Conventional Commit with `Refs #<issue>` footer.
- [ ] Branch created from latest `main` using `<type>/<issue>-<slug>`.
- [ ] Every acceptance criterion satisfied, or blockers explicitly documented.
- [ ] Verification commands executed and terminal output displayed in the report.

**Terraform Changes (when applicable in IaC repo):**
- [ ] `terraform fmt -check -recursive` clean.
- [ ] `terraform validate` clean on all stacks and modules.
- [ ] `tflint` clean.
- [ ] Security scanners (`trivy`/`checkov`) clean or findings justified.
- [ ] Plan-only evidence produced; destroys and replacements explicitly called out.
- [ ] Infracost CLI v2 cost estimation delta published to job summary (`pc-iac-027.md`).
- [ ] Executable plan generated against Floci emulator without cloud credentials (`pc-iac-028.md`).
- [ ] `moved` blocks present for any relocated or renamed resource.

**Documentation and Diagram Changes:**
- [ ] Links resolve and directory maps match the filesystem.
- [ ] Diagrams re-exported to SVG and PNG, inspected at publication size.
- [ ] Architectural decisions recorded in numbered ADRs (`docs/adr/`).

---

## 11. Never / Always Quick Reference

### Never

| Prohibited Action | Rationale |
|---|---|
| Run `terraform apply` or `terraform destroy` | Academic delivery is strictly plan-only (§4). |
| Direct commit to `main` | Trunk-based development requires PRs (§6.1). |
| Force-push (`git push --force`) or merge as implementer | Agents never force-push; implementer agents never merge; designated reviewer agent reviews and merges (§6.5). |
| Use emojis anywhere | Strict Zero-Emoji mandate (§2). |
| Invent values, measurements, or approvals | All requirements originate from `docs/case/case-statement.pdf` (§3). |
| Rename Terraform resource without `moved` block | Renaming in-place causes a destroy and recreate (§8). |
| Put `.tf` files outside Terraform repositories | Terraform belongs strictly in `aroma-pacifico-terraform-modules` and `aroma-pacifico-infrastructure` (§5). |
| Hardcode credentials, account IDs, or secrets | Use variables, data sources, and secret managers (§8). |

### Always

| Required Action | Rationale |
|---|---|
| Write in English | Project-wide consistency (§2). |
| Reference issue in commits (`Refs #<issue>`) | Traceability across git history (§6.4). |
| Commit atomically as you go | Avoid end-of-session bulk commits (§6.3). |
| Keep feature branches under 48 hours | Prevent branch drift and merge debt (§6.2). |
| Log assumptions in `docs/decision-log.md` | Keep all assumptions traceable and numbered (§3). |
| Export diagrams to SVG and PNG | Provide publication-ready visual assets (§9). |
| Show verification output | "Done" requires concrete verification proof (§10). |

---

## 12. Grounding and Dealing with Errors

- When a tool, linter, or compiler contradicts you, the tool is right. Read the documentation and schemas.
- If an acceptance criterion cannot be satisfied, state the gap clearly and document the blocker. Never quietly reduce the scope.
- Maintain institutional transparency: if a check failed, display the failure and the resolution applied.
