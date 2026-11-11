# Inference functions sample

Consuming root that invokes the inference functions module with the four functions of Part E: confirmation (`confrm`), verification (`verify`), estimation (`estim`) and the telemetry threshold function (`thresh`). All values in `terraform.tfvars` are synthetic: `client` and `project` are placeholders, the all-zero account is the fixture value, and no real bucket, table or topic is named. The model identifier is the configuration value of ASM-160.

The sample is validated and tested offline; it is never applied.

```bash
terraform -chdir=modules/inference-functions/sample init -backend=false
terraform -chdir=modules/inference-functions/sample validate
terraform -chdir=modules/inference-functions/sample test
```
