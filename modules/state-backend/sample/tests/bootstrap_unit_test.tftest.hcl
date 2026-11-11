mock_provider "aws" {
  alias           = "principal"
  override_during = plan

  mock_resource "aws_kms_key" {
    defaults = {
      arn    = "arn:aws:kms:us-east-1:000000000000:key/00000000-0000-0000-0000-000000000000"
      key_id = "00000000-0000-0000-0000-000000000000"
    }
  }
}

# The checked-in terraform.tfvars is not loaded by native tests; these variables replace it.
variables {
  client                        = "fx"
  project                       = "cf"
  environment                   = "qa"
  resource_key                  = "state"
  region                        = "us-east-1"
  account_id                    = "000000000000"
  owner                         = "fixture"
  cost_center                   = "fixture"
  key_administrators            = ["arn:aws:iam::000000000000:role/fixture-admin"]
  configuration_readers         = ["arn:aws:iam::000000000000:role/fixture-auditor"]
  break_glass_role_arn_patterns = ["arn:aws:iam::000000000000:role/aws-reserved/sso.amazonaws.com/*/AWSReservedSSO_FixtureBreakGlass_*"]
  domain_access = {
    for domain in ["network", "security", "workload", "state-backend"] : domain => {
      plan_role_arns  = ["arn:aws:iam::000000000000:role/fixture-${domain}-plan"]
      write_role_arns = ["arn:aws:iam::000000000000:role/fixture-${domain}-writer"]
    }
  }
}

run "bootstrap_without_backend" {
  command = plan

  assert {
    condition = length(output.backend_configuration) == 4 && alltrue([
      for domain, config in output.backend_configuration :
      config.bucket == "fx-cf-qa-state" && config.key == "${domain}/terraform.tfstate" && config.encrypt && config.use_lockfile
      && config.region == "us-east-1" && config.allowed_account_ids == ["000000000000"]
    ])
    error_message = "One bootstrap composition must expose four isolated domain keys with encryption, locking and account restriction."
  }
}

run "missing_bootstrap_domain" {
  command = plan

  variables {
    domain_access = {
      network = { plan_role_arns = ["arn:aws:iam::000000000000:role/fixture-network-plan"] }
    }
  }

  expect_failures = [var.domain_access]
}

run "unapproved_region" {
  command = plan

  variables {
    region = "us-west-2"
  }

  expect_failures = [var.region]
}

run "dev_bootstrap_without_backend" {
  command = plan

  variables {
    environment                   = "dev"
    account_id                    = "000000000001"
    key_administrators            = ["arn:aws:iam::000000000001:role/fixture-admin"]
    configuration_readers         = ["arn:aws:iam::000000000001:role/fixture-auditor"]
    break_glass_role_arn_patterns = ["arn:aws:iam::000000000001:role/aws-reserved/sso.amazonaws.com/*/AWSReservedSSO_FixtureBreakGlass_*"]
    domain_access = {
      for domain in ["network", "security", "workload", "state-backend"] : domain => {
        plan_role_arns  = ["arn:aws:iam::000000000001:role/fixture-${domain}-plan"]
        write_role_arns = ["arn:aws:iam::000000000001:role/fixture-${domain}-writer"]
      }
    }
  }

  override_resource {
    target          = module.state_backend.aws_kms_key.state
    values          = { arn = "arn:aws:kms:us-east-1:000000000001:key/00000000-0000-0000-0000-000000000001", key_id = "00000000-0000-0000-0000-000000000001" }
    override_during = plan
  }

  assert {
    condition = length(output.backend_configuration) == 4 && alltrue([
      for domain, config in output.backend_configuration :
      config.bucket == "fx-cf-dev-state" && config.allowed_account_ids == ["000000000001"] && strcontains(config.kms_key_id, ":000000000001:key/")
    ])
    error_message = "Each environment must retain an isolated account, bucket and KMS key."
  }
}

run "pdn_bootstrap_without_backend" {
  command = plan

  variables {
    environment                   = "pdn"
    account_id                    = "000000000002"
    key_administrators            = ["arn:aws:iam::000000000002:role/fixture-admin"]
    configuration_readers         = ["arn:aws:iam::000000000002:role/fixture-auditor"]
    break_glass_role_arn_patterns = ["arn:aws:iam::000000000002:role/aws-reserved/sso.amazonaws.com/*/AWSReservedSSO_FixtureBreakGlass_*"]
    domain_access = {
      for domain in ["network", "security", "workload", "state-backend"] : domain => {
        plan_role_arns  = ["arn:aws:iam::000000000002:role/fixture-${domain}-plan"]
        write_role_arns = ["arn:aws:iam::000000000002:role/fixture-${domain}-writer"]
      }
    }
  }

  override_resource {
    target          = module.state_backend.aws_kms_key.state
    values          = { arn = "arn:aws:kms:us-east-1:000000000002:key/00000000-0000-0000-0000-000000000002", key_id = "00000000-0000-0000-0000-000000000002" }
    override_during = plan
  }

  assert {
    condition = length(output.backend_configuration) == 4 && alltrue([
      for domain, config in output.backend_configuration :
      config.bucket == "fx-cf-pdn-state" && config.allowed_account_ids == ["000000000002"] && strcontains(config.kms_key_id, ":000000000002:key/")
    ])
    error_message = "Each environment must retain an isolated account, bucket and KMS key."
  }
}
