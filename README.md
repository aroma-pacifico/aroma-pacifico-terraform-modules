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

## Tasks delivered here

- [B04](https://github.com/aroma-pacifico/aroma-pacifico-roadmap/issues/24)
- [B05](https://github.com/aroma-pacifico/aroma-pacifico-roadmap/issues/25)
- [B06](https://github.com/aroma-pacifico/aroma-pacifico-roadmap/issues/26)
- [B07](https://github.com/aroma-pacifico/aroma-pacifico-roadmap/issues/27)
- [B08](https://github.com/aroma-pacifico/aroma-pacifico-roadmap/issues/28)
- [B09](https://github.com/aroma-pacifico/aroma-pacifico-roadmap/issues/29)
- [B10](https://github.com/aroma-pacifico/aroma-pacifico-roadmap/issues/30)
