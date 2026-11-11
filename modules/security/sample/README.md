# Security module sample

Consuming root that invokes the security module with synthetic pdn values. Every ARN uses the all-zero fixture account and `client` and `project` are placeholders, because this repository is public.

The sample is validated and tested offline; it is never applied.

```bash
terraform -chdir=modules/security/sample init -backend=false
terraform -chdir=modules/security/sample validate
terraform -chdir=modules/security/sample test
```
