# One-farm workload composition

This complete local verification root invokes exactly one farm module. The `ingestion` object is the typed B09 adapter: environment, endpoint, policy name and topic template containing one `{thing_name}` placeholder. B09 has no published implementation at the delivery baseline, so `terraform.tfvars` and tests use `.invalid` endpoints and synthetic policy names. Those policies are not deployed.

The root reads the two public CSR files, constructs stable names in `locals.tf`, injects `aws.principal` as `aws.project`, and forwards the module's public outputs. Native mocked plans cover dev, qa and pdn. Each creates two things, two certificates, two principal attachments and two policy attachments: eight resources, zero updates/deletes/replacements. No buffering, firmware, hardware, network or ingestion service is implemented here.

```text
terraform -chdir=modules/farm/sample init -backend=false -input=false
terraform -chdir=modules/farm/sample validate
terraform -chdir=modules/farm/sample test -var-file=terraform.tfvars
python scripts/verify-farm.py
```

Use the approved launcher in isolated validation context, without AWS credentials. The empty role placeholder is mock-only and cannot authenticate a standalone account plan. A shared workload uses the separate [production template](../production-template/README.md), a reviewed release and the B02 S3 backend. Public CSRs are not private keys; tests do not prove possession of those keys.
