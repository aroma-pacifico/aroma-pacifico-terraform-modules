mock_provider "aws" {
  alias           = "principal"
  override_during = plan

  mock_data "aws_caller_identity" {
    defaults = { account_id = "000000000000" }
  }

  mock_data "aws_region" {
    defaults = { region = "us-east-1" }
  }

  mock_data "aws_partition" {
    defaults = { partition = "aws" }
  }

  mock_data "aws_iam_policy_document" {
    defaults = { json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}" }
  }
}

run "sample_plans_the_security_baseline" {
  command = plan

  assert {
    condition     = length(output.kms_key_arns) == 8
    error_message = "The sample must plan one key per data class."
  }

  assert {
    condition     = output.mfa_required_roles == tolist(["agronomist", "collection_center_operator", "drone_operator", "platform_operator"])
    error_message = "The sample must require MFA for the three mandatory roles and the agronomist."
  }

  assert {
    condition     = module.security.secure_transport_policy_statements_json != null
    error_message = "The sample must render the secure transport policy for its protected bucket."
  }
}
