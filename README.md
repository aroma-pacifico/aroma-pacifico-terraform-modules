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
