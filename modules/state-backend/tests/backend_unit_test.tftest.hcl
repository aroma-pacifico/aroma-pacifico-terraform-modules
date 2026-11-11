# All identities below are computed synthetic fixtures, never real AWS principals.
mock_provider "aws" {
  alias           = "project"
  override_during = plan
  mock_resource "aws_kms_key" {
    defaults = {
      arn    = "arn:aws:kms:us-east-1:${format("%012d", 0)}:key/00000000-0000-0000-0000-000000000000"
      key_id = "00000000-0000-0000-0000-000000000000"
    }
  }
}

variables {
  client                = "fx"
  project               = "cf"
  environment           = "qa"
  name_prefix           = "fx-cf-qa-state"
  aws_context           = { account_id = format("%012d", 0), partition = "aws", region = "us-east-1" }
  key_administrators    = ["arn:aws:iam::${format("%012d", 0)}:role/fixture-admin"]
  configuration_readers = ["arn:aws:iam::${format("%012d", 0)}:role/fixture-auditor"]
  domain_access = {
    for domain in ["network", "security", "workload", "state-backend"] : domain => {
      plan_role_arns  = ["arn:aws:iam::${format("%012d", 0)}:role/fixture-${domain}-plan"]
      write_role_arns = ["arn:aws:iam::${format("%012d", 0)}:role/fixture-${domain}-writer"]
    }
  }
  additional_tags = { Client = "fx", Project = "cf", Environment = "qa", Owner = "fixture", CostCenter = "fixture" }
}

run "qa_backend" {
  command = plan
  assert {
    condition     = aws_s3_bucket.state.bucket == "fx-cf-qa-state" && !aws_s3_bucket.state.force_destroy && aws_s3_bucket.state.tags.Name == "fx-cf-qa-state"
    error_message = "The selected environment owns one non-destructive bucket with its root-built name."
  }
  assert {
    condition     = aws_s3_bucket_versioning.state.versioning_configuration[0].status == "Enabled" && aws_s3_bucket_ownership_controls.state.rule[0].object_ownership == "BucketOwnerEnforced"
    error_message = "Versioning and ACL-disabled ownership must remain enabled."
  }
  assert {
    condition     = aws_s3_bucket_public_access_block.state.block_public_acls && aws_s3_bucket_public_access_block.state.block_public_policy && aws_s3_bucket_public_access_block.state.ignore_public_acls && aws_s3_bucket_public_access_block.state.restrict_public_buckets
    error_message = "All four public-access controls must be true."
  }
  assert {
    condition     = one(aws_s3_bucket_server_side_encryption_configuration.state.rule).apply_server_side_encryption_by_default[0].sse_algorithm == "aws:kms" && one(aws_s3_bucket_server_side_encryption_configuration.state.rule).apply_server_side_encryption_by_default[0].kms_master_key_id == aws_kms_key.state.arn && !one(aws_s3_bucket_server_side_encryption_configuration.state.rule).bucket_key_enabled
    error_message = "Use the environment CMK and object-scoped KMS encryption context."
  }
  assert {
    condition     = aws_kms_key.state.enable_key_rotation && aws_kms_key.state.rotation_period_in_days == 365 && aws_kms_key.state.deletion_window_in_days == 30 && !aws_kms_key.state.bypass_policy_lockout_safety_check
    error_message = "Rotation, deletion waiting period and lockout protection must match the approved controls."
  }
  assert {
    condition     = output.state_bucket_name == "fx-cf-qa-state" && output.state_bucket_arn == "arn:aws:s3:::fx-cf-qa-state" && output.state_kms_key_arn == aws_kms_key.state.arn && output.state_kms_key_id == aws_kms_key.state.key_id && output.backend_region == "us-east-1"
    error_message = "Expose only the required backend references."
  }
  assert {
    condition     = alltrue([for statement in jsondecode(aws_kms_key.state.policy).Statement : statement.Principal.AWS != "*" && alltrue([for action in statement.Action : !strcontains(action, "*")])])
    error_message = "KMS grants require explicit principals/actions; Resource star is scoped to this key only."
  }
}

run "dev_backend" {
  command = plan
  variables {
    environment     = "dev"
    name_prefix     = "fx-cf-dev-state"
    additional_tags = { Client = "fx", Project = "cf", Environment = "dev", Owner = "fixture", CostCenter = "fixture" }
  }
  assert {
    condition     = output.state_bucket_name == "fx-cf-dev-state" && aws_s3_bucket.state.tags.Environment == "dev" && aws_kms_alias.state.name == "alias/fx-cf-dev-state"
    error_message = "Another environment must reuse the module without creating QA resources."
  }
}

run "pdn_backend" {
  command = plan
  variables {
    environment     = "pdn"
    name_prefix     = "fx-cf-pdn-state"
    additional_tags = { Client = "fx", Project = "cf", Environment = "pdn", Owner = "fixture", CostCenter = "fixture" }
  }
  assert {
    condition     = output.state_bucket_name == "fx-cf-pdn-state" && aws_kms_key.state.tags.Environment == "pdn"
    error_message = "Production must have an independent name and metadata."
  }
}

run "plan_only_domain" {
  command = plan
  variables {
    domain_access = { network = { plan_role_arns = ["arn:aws:iam::${format("%012d", 0)}:role/fixture-network-plan"] } }
  }
  assert {
    condition     = contains([for s in jsondecode(aws_s3_bucket_policy.state.policy).Statement : s.Sid], "DenyAllStateWritesnetwork")
    error_message = "Without approved write identities, state writes must be denied to everyone."
  }
}

run "invalid_environment" {
  command = plan
  variables { environment = "other" }
  expect_failures = [var.environment]
}

run "cross_environment_name" {
  command = plan
  variables { name_prefix = "fx-cf-pdn-state" }
  expect_failures = [var.name_prefix]
}

run "cross_environment_tags" {
  command = plan
  variables { additional_tags = { Client = "fx", Project = "cf", Environment = "pdn", Owner = "fixture", CostCenter = "fixture" } }
  expect_failures = [var.additional_tags]
}

run "wildcard_admin" {
  command = plan
  variables { key_administrators = ["*"] }
  expect_failures = [var.key_administrators]
}

run "root_admin" {
  command = plan
  variables { key_administrators = ["arn:aws:iam::${format("%012d", 0)}:root"] }
  expect_failures = [var.key_administrators]
}

run "empty_admins" {
  command = plan
  variables { key_administrators = [] }
  expect_failures = [var.key_administrators]
}

run "foreign_account_role" {
  command = plan
  variables { domain_access = { network = { plan_role_arns = ["arn:aws:iam::${format("%012d", 1)}:role/fixture-network-plan"] } } }
  expect_failures = [var.domain_access]
}

run "shared_plan_write_identity" {
  command = plan
  variables { domain_access = { network = { plan_role_arns = ["arn:aws:iam::${format("%012d", 0)}:role/fixture-network-plan"], write_role_arns = ["arn:aws:iam::${format("%012d", 0)}:role/fixture-network-plan"] } } }
  expect_failures = [var.domain_access]
}

run "admin_as_data_role" {
  command = plan
  variables { domain_access = { network = { plan_role_arns = ["arn:aws:iam::${format("%012d", 0)}:role/fixture-admin"] } } }
  expect_failures = [var.domain_access]
}

run "invalid_bucket_name" {
  command = plan
  variables { name_prefix = "fx-cf-qa-state.with.dots" }
  expect_failures = [var.name_prefix]
}

run "missing_plan_roles" {
  command = plan
  variables { domain_access = { network = { plan_role_arns = [] } } }
  expect_failures = [var.domain_access]
}

run "no_domains" {
  command = plan
  variables { domain_access = {} }
  expect_failures = [var.domain_access]
}

run "invalid_account" {
  command = plan
  variables { aws_context = { account_id = "invalid", partition = "aws", region = "us-east-1" } }
  expect_failures = [var.aws_context]
}

run "missing_configuration_readers" {
  command = plan
  variables { configuration_readers = [] }
  expect_failures = [var.configuration_readers]
}
