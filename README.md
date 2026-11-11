# aroma-pacifico-terraform-modules

Reusable Terraform reference modules for the Aroma Pacífico pilot, consumed by git tag (pc-iac-015). Public: never commit account identifiers, ARNs or real data

Part of the Aroma Pacífico pilot, the 2026 update of the coffee traceability pilot for Cauca, Huila and Tolima. Work is tracked in [aroma-pacifico-roadmap](https://github.com/aroma-pacifico/aroma-pacifico-roadmap) and on the [Aroma Pacífico Pilot board](https://github.com/orgs/aroma-pacifico/projects/1).

## What lives here

This public repository holds reusable, versioned Terraform reference modules for the Aroma Pacífico pilot, consumed by git tag according to pc-iac-015. Modules strictly declare neither provider nor backend configurations and accept a `name_prefix` input. Because this repository is public, no account identifiers, account-qualified ARNs, internal hostnames, real endpoints, credentials, named principals, or client data are ever committed. Distributed AI agent rules and standards are synchronized here from the canonical `aroma-pacifico-ai-agents` repository.

This repository is plan-only: nothing here may run `terraform apply` or `terraform destroy`, or create a live resource (AGENTS.md section 4).

## Repository layout

```text
aroma-pacifico-terraform-modules/
|-- .github/
|   `-- workflows/                       pr-conventions.yml, module-ci.yml, and infracost.yml
|-- .terraform-version                   exact Terraform patch used by local runs and CI
|-- .tflint.hcl                          TFLint configuration for module and provider linting
|-- infracost.yml                        Infracost project configuration for sample roots
|-- modules/                             one directory per reference module, added by B02 and B04 to B10
|   |-- state-backend/                   B02, S3 and KMS state backend of one environment
|   |-- network/                         B04, box D04
|   |-- collection-center-association/   B05, box D05
|   |-- security-baseline/               B06, box D06
|   |-- firewall-rules/                  B07, box D07
|   |-- farm/                            B08, box D08
|   |-- telemetry-ingestion/             B09, box D09
|   `-- inference-function/              B10, box D10
`-- standards/                           distributed engineering standards
```

Reference modules follow the layout of pc-iac-001, each containing a `sample/` directory and plan-mode tests under `tests/`. Child modules declare no `provider` or `backend` block.

## Versioning and consumption

One SemVer git tag (`vX.Y.Z`) covers the whole repository and is created after each merged module part (ADR-003). A root stack in [aroma-pacifico-infrastructure](https://github.com/aroma-pacifico/aroma-pacifico-infrastructure) pins one tag for all modules and never references a branch or a commit.

```hcl
module "network" {
  source = "git::https://github.com/aroma-pacifico/aroma-pacifico-terraform-modules.git//modules/network?ref=v0.1.0"
}
```

The tag in the example is illustrative; no tag exists yet. Reference modules do not commit `.terraform.lock.hcl`, because a lock file only has meaning in a root stack.

## Prerequisites

| Tool | Version | Notes |
|---|---|---|
| Terraform | 1.15.8, pinned in `.terraform-version` | Modules require `>= 1.14.0`; CI and local runs use the exact patch recorded here. |
| TFLint | 0.55.0 or later | Lints HCL syntax and AWS provider conventions using `.tflint.hcl`. |
| Trivy | 0.36.0 or later | Static security scanner for Terraform misconfigurations. |
| Infracost | 2.18.3, checksum-pinned in CI | FinOps CLI v2 for source-level monthly cost estimation. |
| Git | Any recent release | Branches follow `<type>/<issue-number>-<slug>`; commits follow Conventional Commits. |
| GitHub CLI | Any recent release | Needed to open pull requests and inspect checks. |

No cloud credentials are needed and none may ever be configured for this repository. Module CI runs on mock providers.

## Continuous Integration and Quality Gates

The repository enforces three automated workflow gates in GitHub Actions:

| Workflow | File | Trigger | Responsibility |
|---|---|---|---|
| PR conventions | `.github/workflows/pr-conventions.yml` | `pull_request` (opened, edited, synchronize, reopened) | Conventional Commit PR title and commits, `<type>/<issue>-<slug>` branch naming, and strict zero-emoji mandate. |
| Module CI | `.github/workflows/module-ci.yml` | `pull_request` to `main`, `push` to `main`, `workflow_dispatch` | Matrix validation over every module in `modules/*` and its `sample/` root. |
| Infracost cost impact | `.github/workflows/infracost.yml` | `pull_request` to `main`, `push` to `main`, `workflow_dispatch` | FinOps before/after/delta cost estimation across all sample roots using Infracost CLI v2. |

### Module CI Quality Gates

Every reference module and sample root undergoes six mandatory checks:

1. **Formatting**: `terraform fmt -check -diff` verifies canonical HCL indentation and styling.
2. **Initialization**: `terraform init -backend=false -input=false` downloads required provider plugins without configuring remote state.
3. **Validation**: `terraform validate` verifies syntax and resource configuration consistency. Child modules declaring `configuration_aliases = [aws.project]` (PC-IAC-005) receive a temporary local provider stub during standalone validation.
4. **Linting**: `tflint --compact` verifies Terraform style conventions and AWS provider best practices defined in `.tflint.hcl`.
5. **Security Scanning**: `trivy config --severity HIGH,CRITICAL` detects security misconfigurations and insecure defaults.
6. **Unit Testing**: `terraform test` executes plan-mode assertion scenarios against mocked providers, requiring zero live cloud credentials.

### Infracost FinOps Estimation

The `Infracost cost impact` workflow computes the monthly financial difference between the base revision and the incoming change:

- **Checksum-Pinned CLI**: Runs Infracost CLI v2.18.3 verified with SHA-256 (`0950674d6e19eee5c492e59b415f3078c7c6b72421f940543c6cfa884692874e`).
- **Sample Root Evaluation**: Scans all `sample/` roots declared in `infracost.yml` using synthetic input profiles (`terraform.tfvars`).
- **Summary Publication**: Publishes a comparative Before, After, and Delta monthly cost breakdown per sample root to `$GITHUB_STEP_SUMMARY`.
- **Zero Credentials and No Deployments**: Never touches AWS, never runs `terraform apply`, and never creates cloud resources.
- **Graceful Token Handling**: When the repository secret `INFRACOST_CLI_TOKEN` or repository variables `INFRACOST_ORG` and `INFRACOST_METADATA_EGRESS_APPROVED` (`true`) are not present, the job outputs an explicit estimate unavailable notice and passes without claiming numbers.
- **Untrusted PR Protection**: Forks and Dependabot contributions are prevented from accessing pricing secrets, publishing an explanation notice instead.

### Required Secrets and Variables

| Name | Type | Purpose |
|---|---|---|
| `INFRACOST_CLI_TOKEN` | Repository Secret | Infracost CLI v2 organization authentication token. |
| `INFRACOST_ORG` | Repository Variable | Infracost organization slug (e.g. `aroma-pacifico`). |
| `INFRACOST_METADATA_EGRESS_APPROVED` | Repository Variable | Set to `true` to approve metadata queries to the Infracost pricing service. |

## Base commands

Run from the repository root to verify modules locally.

```bash
# Format check across every module
terraform fmt -check -recursive

# Validate one module through its sample root, without touching state
terraform -chdir=modules/<name>/sample init -backend=false
terraform -chdir=modules/<name>/sample validate

# Lint with TFLint
tflint --init
tflint --recursive

# Static security scan with Trivy
trivy config --severity HIGH,CRITICAL modules

# Plan-mode unit tests with mock providers
terraform -chdir=modules/<name> test
terraform -chdir=modules/<name>/sample test

# Local Infracost scan (requires Infracost CLI v2 and login/token)
infracost scan .
```

## Branch protection

The `main` branch must be protected and reached only through pull requests. Enabling it requires repository administrator rights, so it is a manual step for the organization lead and is not configured by the code in this repository.

## Tasks delivered here

- [B02](https://github.com/aroma-pacifico/aroma-pacifico-roadmap/issues/22)
- [B04](https://github.com/aroma-pacifico/aroma-pacifico-roadmap/issues/24)
- [B05](https://github.com/aroma-pacifico/aroma-pacifico-roadmap/issues/25)
- [B06](https://github.com/aroma-pacifico/aroma-pacifico-roadmap/issues/26)
- [B07](https://github.com/aroma-pacifico/aroma-pacifico-roadmap/issues/27)
- [B08](https://github.com/aroma-pacifico/aroma-pacifico-roadmap/issues/28)
- [B09](https://github.com/aroma-pacifico/aroma-pacifico-roadmap/issues/29)
- [B10](https://github.com/aroma-pacifico/aroma-pacifico-roadmap/issues/30)
- [G02](https://github.com/aroma-pacifico/aroma-pacifico-roadmap/issues/42)
