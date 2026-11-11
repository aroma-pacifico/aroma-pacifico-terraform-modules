# Telemetry ingestion module sample

Consuming root that invokes the telemetry ingestion module with synthetic pdn values. The role, key and queue ARNs use the all-zero fixture account, and `client` and `project` are placeholders, because this repository is public.

The sample is validated and tested offline; it is never applied.

```bash
terraform -chdir=modules/telemetry-ingestion/sample init -backend=false
terraform -chdir=modules/telemetry-ingestion/sample validate
terraform -chdir=modules/telemetry-ingestion/sample test
```
