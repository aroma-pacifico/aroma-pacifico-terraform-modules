# aroma-pacifico-terraform-modules

## State backend module (B02)

[modules/state-backend](modules/state-backend/README.md) models one environment's
S3/KMS remote-state infrastructure. Its mock-only sample and
[policy verifier](scripts/verify-state-backend.py) provide reproducible offline
evidence. It is unreleased; AWS verification and production integration remain
partial. Refs aroma-pacifico/aroma-pacifico-roadmap#22.

Reusable Terraform reference modules for the Aroma Pacífico pilot, consumed by git tag (pc-iac-015). Public: never commit account identifiers, ARNs or real data

Part of the Aroma Pacífico pilot, the 2026 update of the coffee traceability pilot for Cauca, Huila and Tolima. Work is tracked in [aroma-pacifico-roadmap](https://github.com/aroma-pacifico/aroma-pacifico-roadmap) and on the [Aroma Pacífico Pilot board](https://github.com/orgs/aroma-pacifico/projects/1).

## What lives here

This public repository holds reusable, versioned Terraform reference modules for the Aroma Pacífico pilot, consumed by git tag according to pc-iac-015. Modules strictly declare neither provider nor backend configurations and accept a `name_prefix` input. Because this repository is public, no account identifiers, account-qualified ARNs, internal hostnames, real endpoints, credentials, named principals, or client data are ever committed. Distributed AI agent rules and standards are synchronized here from the canonical `aroma-pacifico-ai-agents` repository.

This repository is plan-only: nothing here may run `terraform apply` or `terraform destroy`, or create a live resource (AGENTS.md section 4).

## Repository layout

```text
aroma-pacifico-terraform-modules/
|-- .github/
|   `-- workflows/                       pr-conventions.yml now; the module CI is added with the first module
|-- .terraform-version                   exact Terraform patch used by local runs and CI
|-- modules/                             one directory per reference module, added by B04 to B10
|   |-- network/                         B04, box D04
|   |-- collection-center-association/   B05, box D05
|   |-- security-baseline/               B06, box D06
|   |-- firewall-rules/                  B07, box D07
|   |-- farm/                            B08, box D08
|   |-- telemetry-ingestion/             B09, box D09
|   `-- inference-function/              B10, box D10
`-- standards/                           distributed engineering standards
```

Only `modules/.gitkeep` exists today; each module directory is created by the task that codes it. Each module follows the layout of pc-iac-001, with a `sample/` directory and plan-mode tests under `tests/`, and has no `provider` or `backend` block.

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
| Git | Any recent release | Branches follow `<type>/<issue-number>-<slug>`; commits follow Conventional Commits. |
| GitHub CLI | Any recent release | Needed to open pull requests. |

No cloud credentials are needed and none may ever be configured for this repository. Module CI runs on mock providers.

## Base commands

Run from the repository root, once a module exists.

```bash
# Format check across every module
terraform fmt -check -recursive

# Validate one module through its sample root, without touching state
terraform -chdir=modules/<name>/sample init -backend=false
terraform -chdir=modules/<name>/sample validate

# Plan-mode unit tests with mock providers
terraform -chdir=modules/<name> test
```

## Branch protection

The `main` branch must be protected and reached only through pull requests. Enabling it requires repository administrator rights, so it is a manual step for the organization lead and is not configured by the code in this repository.

## Tasks delivered here

- [B04](https://github.com/aroma-pacifico/aroma-pacifico-roadmap/issues/24)
- [B05](https://github.com/aroma-pacifico/aroma-pacifico-roadmap/issues/25)
- [B06](https://github.com/aroma-pacifico/aroma-pacifico-roadmap/issues/26)
- [B07](https://github.com/aroma-pacifico/aroma-pacifico-roadmap/issues/27)
- [B08](https://github.com/aroma-pacifico/aroma-pacifico-roadmap/issues/28)
- [B09](https://github.com/aroma-pacifico/aroma-pacifico-roadmap/issues/29)
- [B10](https://github.com/aroma-pacifico/aroma-pacifico-roadmap/issues/30)
