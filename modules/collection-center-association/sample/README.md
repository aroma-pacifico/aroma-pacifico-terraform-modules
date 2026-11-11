# Association sample root

This complete local root injects the workload and hub providers into one reusable association. Required inputs are defined in `variables.tf`; `terraform.tfvars` holds synthetic fixtures so that the root plans against the Floci emulator (PC-IAC-028) and in the Infracost scan, and the native tests generate their own values. Run backend-disabled init, validate, `terraform test` and a speculative `terraform plan` against Floci. No `apply` and no local persistent state. See the [module contract](../README.md).
