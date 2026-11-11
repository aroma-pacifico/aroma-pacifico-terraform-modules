# Offline bootstrap composition

This development-only root composes one state-backend child, injects `aws.project` from
`aws.principal` and returns the future S3 backend settings for the four state domains. It has no
backend block because its own bucket does not exist yet. The native tests use a mock provider with
`command = plan`, so they neither persist shared state nor call AWS.

`terraform.tfvars` holds synthetic values only: the all-zero fixture account and fixture role
names. Real identities come from B03 and B06 in the private root. Do not apply or deploy this
sample.

```text
terraform init -backend=false -input=false
terraform validate
terraform test
terraform plan -var-file=terraform.tfvars
```

The last command needs an AWS-compatible endpoint, for example a local Floci emulator, and test
credentials. See the [module contract](../README.md) for access, bootstrap and governance limits.
