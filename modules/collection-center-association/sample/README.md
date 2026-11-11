# Mock-only association root

This complete local root injects workload and hub providers into one reusable association. Required inputs are defined in `variables.tf`; synthetic values are generated only in `tests/association_sample_test.tftest.hcl`. Run backend-disabled init, validate, and `terraform test`. No standalone account plan or local persistent state is part of this example. See the [module contract](../README.md).
