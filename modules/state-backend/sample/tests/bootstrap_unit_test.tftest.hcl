mock_provider "aws" {
  alias           = "principal"
  override_during = plan
  mock_resource "aws_kms_key" {
    defaults = {
      arn    = "arn:aws:kms:us-east-1:${format("%012d", 0)}:key/00000000-0000-0000-0000-000000000000"
      key_id = "00000000-0000-0000-0000-000000000000"
    }
  }
}
variables {
  configuration = {
    client                = "fx", project = "cf", environment = "qa", resource_key = "state"
    aws_context           = { account_id = format("%012d", 0), partition = "aws", region = "us-east-1" }
    execution_role_arn    = "arn:aws:iam::${format("%012d", 0)}:role/fixture-auditor"
    owner                 = "fixture", cost_center = "fixture"
    key_administrators    = ["arn:aws:iam::${format("%012d", 0)}:role/fixture-admin"]
    configuration_readers = ["arn:aws:iam::${format("%012d", 0)}:role/fixture-auditor"]
    domain_access = {
      for domain in ["network", "security", "workload", "state-backend"] : domain => {
        plan_role_arns  = ["arn:aws:iam::${format("%012d", 0)}:role/fixture-${domain}-plan"]
        write_role_arns = ["arn:aws:iam::${format("%012d", 0)}:role/fixture-${domain}-writer"]
      }
    }
  }
}
run "bootstrap_without_backend" {
  command = plan
  assert {
    condition     = length(output.backend_configuration) == 4 && alltrue([for domain, config in output.backend_configuration : config.bucket == "fx-cf-qa-state" && config.key == "${domain}/terraform.tfstate" && config.encrypt && config.use_lockfile && config.region == "us-east-1" && config.allowed_account_ids == [format("%012d", 0)]])
    error_message = "One bootstrap composition must expose four isolated domain keys with encryption, locking and account restriction."
  }
}
run "missing_bootstrap_domain" {
  command = plan
  variables {
    configuration = {
      client                = "fx", project = "cf", environment = "qa", resource_key = "state"
      aws_context           = { account_id = format("%012d", 0), partition = "aws", region = "us-east-1" }
      execution_role_arn    = "arn:aws:iam::${format("%012d", 0)}:role/fixture-auditor"
      owner                 = "fixture", cost_center = "fixture"
      key_administrators    = ["arn:aws:iam::${format("%012d", 0)}:role/fixture-admin"]
      configuration_readers = ["arn:aws:iam::${format("%012d", 0)}:role/fixture-auditor"]
      domain_access         = { network = { plan_role_arns = ["arn:aws:iam::${format("%012d", 0)}:role/fixture-network-plan"] } }
    }
  }
  expect_failures = [var.configuration]
}
