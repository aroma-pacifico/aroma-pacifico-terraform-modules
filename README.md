# aroma-pacifico-terraform-modules

Reusable Terraform reference modules for the Aroma Pacífico pilot, consumed by git tag (pc-iac-015). Public: never commit account identifiers, ARNs or real data

Part of the Aroma Pacífico pilot, the 2026 update of the coffee traceability pilot for Cauca, Huila and Tolima. Work is tracked in [aroma-pacifico-roadmap](https://github.com/aroma-pacifico/aroma-pacifico-roadmap) and on the [Aroma Pacífico Pilot board](https://github.com/orgs/aroma-pacifico/projects/1).

## What lives here

This public repository holds reusable, versioned Terraform reference modules for the Aroma Pacífico pilot, consumed by git tag according to pc-iac-015. Modules strictly declare neither provider nor backend configurations and accept a `name_prefix` input. Because this repository is public, no account identifiers, account-qualified ARNs, internal hostnames, real endpoints, credentials, named principals, or client data are ever committed. Distributed AI agent rules and standards are synchronized here from the canonical `aroma-pacifico-ai-agents` repository.

## Farm pattern (D08, unreleased)

[The farm module](modules/farm/README.md) represents one farm's two logical
IoT node identities and ingestion connection points. Mocked plan tests create
no AWS resources. Environment integration and PD-071 cost-tag resolution remain
pending; no release tag or deployable root integration is claimed.
Read [D08 technical evidence](docs/d08-technical-evidence.md), the
[integration decision register](docs/decision-log.md) and
[troubleshooting log](docs/troubleshooting-log.md).

```text
modules/farm/
|-- main.tf, variables.tf, locals.tf, outputs.tf, versions.tf
|-- data.tf, providers.tf, README.md, CHANGELOG.md, .gitignore
|-- sample/ (one root invocation and mocked environment association tests)
`-- tests/ (plan-mode tests and synthetic public CSR fixtures)
scripts/verify-farm.py
docs/ (d08-technical-evidence.md, decision-log.md, troubleshooting-log.md)
```

## Tasks delivered here

- [B04](https://github.com/aroma-pacifico/aroma-pacifico-roadmap/issues/24)
- [B05](https://github.com/aroma-pacifico/aroma-pacifico-roadmap/issues/25)
- [B06](https://github.com/aroma-pacifico/aroma-pacifico-roadmap/issues/26)
- [B07](https://github.com/aroma-pacifico/aroma-pacifico-roadmap/issues/27)
- [B08](https://github.com/aroma-pacifico/aroma-pacifico-roadmap/issues/28)
- [B09](https://github.com/aroma-pacifico/aroma-pacifico-roadmap/issues/29)
- [B10](https://github.com/aroma-pacifico/aroma-pacifico-roadmap/issues/30)
