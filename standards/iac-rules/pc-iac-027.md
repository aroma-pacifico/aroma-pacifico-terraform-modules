# PC-IAC-027: Automated Cost Estimation in CI/CD Pipelines with Infracost CLI v2

**ID:** PC-IAC-027  
**Type:** Cost Optimization / CI/CD Governance  
**AWS Well-Architected Pillars:** Cost Optimization, Operational Excellence  
**Version:** 1.0  
**Date:** November 2026  

---

## 1. Purpose and Scope

This rule establishes mandatory automated cost estimation requirements for all Infrastructure as Code (IaC) delivery pipelines across the Aroma Pacífico organization. Its objective is to provide continuous visibility into projected cloud expenditures before code reaches trunk, preventing accidental budget overruns on cloud services while preserving security and reproducibility.

This rule applies to all Terraform pipelines across:
- `aroma-pacifico-infrastructure`: Root stacks representing the pattern environment.
- `aroma-pacifico-terraform-modules`: Reusable reference modules with example deployments.
- Any future IaC delivery repository maintained under the Aroma Pacífico organization.

---

## 2. Alignment with Academic Delivery Model (Plan-Only)

As confirmed by the faculty advisor, the Aroma Pacífico project operates under a strict plan-only academic delivery scope:
- **No Cloud Deployments**: Live cloud infrastructure is never created.
- **Prohibited Operations**: Commands `terraform apply` and `terraform destroy` are strictly prohibited for both automated pipelines and AI coding agents.
- **Pipeline Proof of Deployability**: Pipelines must nonetheless prove conclusively that configuration would succeed if deployed. This proof comprises automated formatting checks, syntax and schema validation (`terraform validate`), security and linting gates, plan-mode tests (`.tftest.hcl`), reviewable speculative execution plans (`terraform plan`), and automated cost estimates.

Under this model, cost estimation provides necessary fiscal evidence for architecture evaluation without incurring real-world resource expenditure.

---

## 3. Mandatory Infracost CLI v2 Cost Estimation

Every IaC pipeline must integrate automated monthly cost estimation utilizing Infracost CLI v2.

### 3.1. Pipeline Integration Points

Cost estimation must execute in two distinct pipeline stages:
1. **Pull Request CI**: Evaluates proposed changes on feature branches targeting `main`, calculating the cost delta before peer review and merging.
2. **CD Promotion with Production Approval**: Evaluates environment promotions and renders cost estimates alongside the speculative execution plan for human reviewer and lead evaluation.

### 3.2. Output and Reporting Requirements

The pipeline must parse Infracost outputs and publish a structured breakdown to the GitHub Actions Job Summary (`$GITHUB_STEP_SUMMARY`):
- **Previous Monthly Cost**: Projected baseline cost prior to the proposed change.
- **New Monthly Cost**: Projected total cost after applying the proposed change.
- **Monthly Cost Delta**: Net change (absolute value and percentage) introduced by the pull request.
- **Per-Root Granularity**: For repositories containing multiple root stacks or module examples, each root configuration must be reported distinctly.
- **Production Approval Association**: In production deployment promotion workflows, the Infracost cost summary must be displayed directly adjacent to the speculative `terraform plan` output prior to approval.

---

## 4. Authentication, Configuration, and Variables

Infracost CLI v2 operates under an organization-level governance model. Configurations must adhere strictly to the following parameters:

### 4.1. Secrets and Environment Variables

- **Secret Name**: `INFRACOST_CLI_TOKEN`.
- **Token Type**: Must be a CLI v2 token belonging to the Infracost organization `aroma-pacifico`.
- **Environment Mapping**: Passed into the runner environment as:
  ```bash
  INFRACOST_CLI_AUTHENTICATION_TOKEN: ${{ secrets.INFRACOST_CLI_TOKEN }}
  ```
- **Rejection of Legacy Keys**: Legacy API keys prefixed with `ico-` are strictly prohibited and rejected by pipeline policies.

### 4.2. Repository Variables

The following repository-level variables are pre-configured across `aroma-pacifico-infrastructure` and `aroma-pacifico-terraform-modules`:
- `INFRACOST_ORG`: Must equal `aroma-pacifico`.
- `INFRACOST_METADATA_EGRESS_APPROVED`: Must equal `true` to authorize metadata egress required for pricing API lookups.

### 4.3. Credential-Free Execution

Infracost parses Terraform configuration, variable definitions, and provider schemas locally to query public cloud pricing APIs:
- Cost estimation requires zero cloud credentials. No AWS access keys, AWS secret tokens, Azure service principal credentials, or IAM role assumptions are provided to the Infracost job step.
- Parsing runs entirely within an isolated runner context without read or write permissions to cloud resources.

---

## 5. Resilient Fallback and Fork Protection

Pipelines must handle scenarios where organizational secrets are inaccessible (e.g., Dependabot branches, external forks):
- When `INFRACOST_CLI_TOKEN` is unavailable, the pipeline step must not fail.
- Instead, the step must log a fallback notice: `estimate unavailable`.
- The pipeline must not generate arbitrary, placeholder, or estimated figures when the token is missing.

---

## 6. Supply Chain Security and Immutability

To protect pipeline integrity against supply chain attacks, all Infracost components must be pinned:
1. **Binary Checksum Pinning**: When downloading the Infracost CLI executable directly, sha256 checksums must be validated prior to invocation.
2. **Action SHA Pinning**: All GitHub Actions (e.g., `infracost/actions/setup`) must be referenced by immutable 40-character commit SHAs, never by mutable semantic version tags or branch heads.

---

## 7. Scope Boundaries and Notifications

- **External Chat Notifications**: Slack, Microsoft Teams, or Discord automated webhook notifications are NOT required for cost estimation. The term "notify" in project case specifications refers exclusively to structured release-note templates generated during release milestones.
- **Traceability**: This rule formalizes the acceptance criteria established in roadmap issues #31 (B11: Infrastructure CI/CD pipeline), #32 (B12: Production promotion pipeline), and G02 (#42: Modules repository Infracost integration).

---

## 8. Compliance Checklist

| Item | Requirement | Verification Method |
|---|---|---|
| Infracost Version | Infracost CLI v2 | `infracost --version` |
| Token Secret | `INFRACOST_CLI_TOKEN` as `INFRACOST_CLI_AUTHENTICATION_TOKEN` | Workflow inspection |
| Organization | `INFRACOST_ORG=aroma-pacifico` | Workflow variable check |
| Egress Approval | `INFRACOST_METADATA_EGRESS_APPROVED=true` | Workflow variable check |
| Legacy Keys | No `ico-` prefixed keys used | Static code analysis |
| Cloud Credentials | Zero cloud credentials exposed to Infracost step | Environment audit |
| Job Summary | Before, after, and delta published to job summary | PR execution check |
| Missing Token | Emits "estimate unavailable", exits cleanly | Fork/untrusted run simulation |
| Pinning | Actions pinned by commit SHA; CLI pinned by checksum | Workflow inspection |
