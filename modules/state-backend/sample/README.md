# Offline bootstrap composition

This development-only root composes one state-backend child, injects aws.project
from aws.principal and returns future S3 settings for four domains. There is no
backend block because its own bucket does not yet exist. Native tests use mock
providers with command=plan; they neither persist shared state nor call AWS.

The terraform.tfvars file is intentionally non-operational. Tests override it
with synthetic account/role expressions. Real B03/B06 identities, configuration
and a reviewed module release are unavailable. Do not apply or deploy this sample.

After backend-disabled init, run terraform validate and terraform test. The
checked-in root lock selects AWS 6.0.0. Runtime key-creation authorization,
backend IAM behavior and migration are not verified by these mocks. See the
[module contract](../README.md) for access, bootstrap and governance limits.
