# Aroma Pacifico Terraform modules

This public repository holds reusable modules. Roots belong in [infrastructure](https://github.com/aroma-pacifico/aroma-pacifico-infrastructure). Governance and standards are synchronized from ai-agents and are never edited here.

Reviewed main contains `network`, `security` and `inference-functions`. This feature branch adds [collection-center-association](modules/collection-center-association/README.md). Other owners' reviewed modules remain unchanged. Each module has its required source files, native plan tests, and a complete local `sample/` root; this branch also contains `scripts/` verification and `docs/b05-final-delivery.md` evidence.

Terraform 1.15.8 is recorded in `.terraform-version`; modules require at least 1.14.0 and AWS 6.0.0. Children declare provider aliases without configuring providers or backends. Sample roots inject those aliases, pin the tested provider and own their lockfiles.

```text
terraform fmt -check -recursive
terraform -chdir=modules/collection-center-association init -backend=false -input=false
terraform -chdir=modules/collection-center-association test
terraform -chdir=modules/collection-center-association/sample init -backend=false -input=false
terraform -chdir=modules/collection-center-association/sample validate
terraform -chdir=modules/collection-center-association/sample test
```

Use the approved launcher in isolated validation context without AWS credentials. B08's sample also takes `-var-file=terraform.tfvars`; additional steps are in each module README. Every resource plan is **OFFLINE MOCKED TERRAFORM PLAN**. No account plan, cloud operation or persistent state is claimed.

Shared consumption requires a genuine reviewed SemVer git tag. None is published or invented. Local sources are restricted to verification fixtures; production templates retain their release gates. Independent review, acceptance, releases and main protection remain lead/reviewer actions. Implementers do not merge.

See [final evidence](docs/b05-final-delivery.md), [AGENTS.md](AGENTS.md), [Contributing](CONTRIBUTING.md) and [standards](standards/terraform-iac-best-practices.md).


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

