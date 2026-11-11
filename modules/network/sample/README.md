# Network module sample

Consuming root that invokes the network module with the pdn values of the addressing plan (section 4.3). All values in `terraform.tfvars` are synthetic: `client` and `project` are placeholders and no account identifier, hostname or real address appears, because this repository is public.

The sample is validated and tested offline; it is never applied.

```bash
terraform -chdir=modules/network/sample init -backend=false
terraform -chdir=modules/network/sample validate
terraform -chdir=modules/network/sample test
```
