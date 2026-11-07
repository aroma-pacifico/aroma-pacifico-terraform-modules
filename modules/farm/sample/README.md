# Offline root composition example

This sample calls one child via `source = "../"`, the local-development method
permitted by PC-IAC-015 and PC-IAC-026. It never expands a farm inventory.
The flow is `terraform.tfvars -> variables.tf -> locals.tf -> main.tf -> ../`.
Resource logic exists only in the child. No data discovery is attempted because
the ingestion module and runtime root interfaces have not been released.

All values are synthetic: the endpoint uses reserved `.invalid`, policy/farm
names are fixtures, and the CSRs contain public requests only. Temporary keys
used to generate those test requests were deleted outside the repository.
The empty role reference is an explicitly mock-only placeholder; do not run
a standalone account plan or deployment from this sample.

Use Terraform >= 1.14.0 and the root lockfile (AWS 6.0.0):

```text
terraform -chdir=modules/farm/sample init -backend=false -input=false
terraform -chdir=modules/farm/sample validate
terraform -chdir=modules/farm/sample test "-var-file=terraform.tfvars"
```

Both test runs explicitly use `command = plan` with a mocked `aws.principal`.
They do not configure an AWS identity, call AWS, create state on disk or apply.
No backend is needed for in-memory tests. Shared-environment roots must supply
the real provider/remote backend, reviewed ingestion contracts and a released
module SemVer tag; no version has been invented here. Never promote the local
source or fixture values to a shared environment.

```text
sample/
|-- README.md
|-- .terraform.lock.hcl
|-- data.tf, locals.tf, main.tf, outputs.tf
|-- providers.tf, variables.tf, versions.tf, terraform.tfvars
`-- tests/association_unit_test.tftest.hcl
```
