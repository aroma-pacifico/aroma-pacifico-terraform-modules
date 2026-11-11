# PC-IAC-028: AWS Emulation with Floci for Executable Plan Evidence

**ID:** PC-IAC-028  
**Type:** Local Development / CI Governance / Emulation Standards  
**AWS Well-Architected Pillars:** Operational Excellence, Cost Optimization  
**Version:** 1.0  
**Date:** November 2026  

---

## 1. Purpose and Scope

This rule establishes Floci as the official AWS emulation target for generating executable `terraform plan` evidence across all Aroma Pacífico Infrastructure as Code (IaC) repositories. The faculty advisor formally accepted Floci in lieu of live AWS account provisioning.

This rule applies to all Terraform pipelines and local developer workflows across:
- `aroma-pacifico-terraform-modules`: Reusable reference modules and sample configurations.
- `aroma-pacifico-infrastructure`: Root stacks representing the pattern environment.
- Any future IaC repository delivered under the Aroma Pacífico organization.

---

## 2. Alignment with Academic Plan-Only Scope

The Aroma Pacífico project operates under an academic delivery model restricted to static validation and speculative execution plans:
- **Strict Prohibition of Apply and Destroy**: Executing `terraform apply` or `terraform destroy` is prohibited across all environments, including local Floci containers, CI service runners, and cloud providers.
- **Speculative Plan Delivery**: Delivery criteria require proving that Terraform configurations are syntactically valid, schema-compliant, and executable. Floci provides an authentic AWS API surface for `terraform init` and `terraform plan` without incurring cloud costs or requiring live credentials.
- **Emulation Boundaries**: Floci is an emulator (an MIT-licensed LocalStack drop-in), not a replica of physical AWS infrastructure. Plans verify resource graphs and attribute bindings, but live resource instantiation remains out of scope.

---

## 3. Pinned Container Image Specification

All local environments and CI pipelines must pin the exact image digest for Floci 2.4.0. Pinning guarantees identical emulation behavior across machines and protects against supply chain regressions.

- **Repository**: `floci/floci`
- **Release Version**: 2.4.0 (created 2026-10-31)
- **Pinned Digest**:
  ```text
  floci/floci@sha256:5ee85db604c4aa74ac76e07ea5cc83086f37bb472bf3dbb97e34019e48efae9c
  ```
- **Digest Enforcement**: Workflows and local compose definitions must reference this digest directly. Plain semantic tags such as `:latest` or `:2.4.0` are forbidden.

---

## 4. Execution Environment and Provider Compatibility

The AWS provider for Terraform (v6.x) natively respects the standard `AWS_ENDPOINT_URL` environment variable. Zero modifications to `.tf` provider configurations are required.

### 4.1. Standard Environment Variables

All Terraform executions against Floci must export the following standard environment configuration:

```bash
export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_REGION=us-east-1
```

### 4.2. Provider Emulation Behaviors

- **AWS STS**: Responds to identity verification requests by returning mock account ID `000000000000`.
- **Amazon EC2**: Availability zone queries in `us-east-1` resolve consistently to `us-east-1a`, `us-east-1b`, and `us-east-1c`.
- **Harmless Container Warnings**: Floci logs a warning that Docker is unreachable inside its container environment. This message affects only runtime services executing child containers (such as live Lambda execution or mock EC2 instances) and has zero impact on `terraform plan` evaluation.
- **Plugin Cache Acceleration**: Downloading the AWS provider plugin (e.g. v6.72) repeatedly introduces network overhead. Workflows should configure `TF_PLUGIN_CACHE_DIR` with GitHub Actions cache actions to optimize pipeline duration.

---

## 5. Local Docker Workflow

Developers and coding agents execute speculative plans locally by running the Floci container in the background:

```bash
# Start Floci container pinned by digest
docker run -d --rm \
  --name floci \
  -p 4566:4566 \
  floci/floci@sha256:5ee85db604c4aa74ac76e07ea5cc83086f37bb472bf3dbb97e34019e48efae9c

# Configure environment
export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_REGION=us-east-1

# Run speculative plan without state locks or backend dependencies
terraform init -backend=false
terraform plan -lock=false
```

During validation spikes on Floci 2.4.0, sample configurations across `network`, `security`, and `inference-functions` planned 163, 27, and 36 resources respectively with clean exit status 0.

---

## 6. GitHub Actions CI Service Container

Automated pull request validation workflows integrate Floci via GitHub Actions job services.

```yaml
jobs:
  validate-plan:
    runs-on: ubuntu-latest
    services:
      floci:
        image: floci/floci@sha256:5ee85db604c4aa74ac76e07ea5cc83086f37bb472bf3dbb97e34019e48efae9c
        ports:
          - 4566:4566
    env:
      AWS_ENDPOINT_URL: http://localhost:4566
      AWS_ACCESS_KEY_ID: test
      AWS_SECRET_ACCESS_KEY: test
      AWS_REGION: us-east-1
      TF_PLUGIN_CACHE_DIR: ${{ github.workspace }}/.terraform.d/plugin-cache
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Cache Terraform plugins
        uses: actions/cache@v4
        with:
          path: ${{ github.workspace }}/.terraform.d/plugin-cache
          key: ${{ runner.os }}-terraform-${{ hashFiles('**/.terraform.lock.hcl') }}
          restore-keys: |
            ${{ runner.os }}-terraform-

      - name: Initialize and Plan
        run: |
          terraform init -backend=false
          terraform plan -lock=false -no-color | tee plan.txt

      - name: Publish Plan Summary
        if: always()
        run: |
          echo "### Terraform Plan Summary (Floci Emulator)" >> $GITHUB_STEP_SUMMARY
          echo '```text' >> $GITHUB_STEP_SUMMARY
          tail -n 25 plan.txt >> $GITHUB_STEP_SUMMARY
          echo '```' >> $GITHUB_STEP_SUMMARY
```

---

## 7. Remote State S3 Backend Evidence on Floci

For roadmap tasks demonstrating remote state management (such as B02 / issue #22), Floci provides S3 and DynamoDB API endpoints to validate state storage and locking:

1. **Bucket Creation**: Create the designated state bucket dynamically against the Floci endpoint:
   ```bash
   aws --endpoint-url=http://localhost:4566 s3 mb s3://aroma-pacifico-terraform-state
   ```
2. **Backend Configuration Arguments**: Initialize the backend using dynamic command-line flags rather than committing environment-specific endpoints or hardcoded bucket names to repository code:
   ```bash
   terraform init \
     -backend-config="endpoint=http://localhost:4566" \
     -backend-config="bucket=aroma-pacifico-terraform-state" \
     -backend-config="key=pattern/terraform.tfstate" \
     -backend-config="region=us-east-1" \
     -backend-config="use_path_style=true" \
     -backend-config="use_lockfile=true"
   ```
3. **Information Security**: Never commit real AWS bucket names, production account numbers, or live state files to version control.

---

## 8. Compliance Checklist

| Item | Requirement | Verification Method |
|---|---|---|
| Container Image | Pinned to `floci/floci@sha256:5ee85db604c4aa74ac76e07ea5cc83086f37bb472bf3dbb97e34019e48efae9c` | Workflow and compose inspection |
| Environment Mapping | `AWS_ENDPOINT_URL=http://localhost:4566`, test keys, `us-east-1` | Environment audit |
| Scope Discipline | Plan-only execution; `apply` and `destroy` strictly forbidden | Pipeline and command logs |
| Code Purity | Zero provider block overrides in reusable Terraform code | Code review |
| State Evidence | S3 backend configured via `-backend-config` using path style and lockfile | Verification scripts |
| Plugin Caching | `TF_PLUGIN_CACHE_DIR` configured in CI to reduce provider download latency | Workflow definition review |
