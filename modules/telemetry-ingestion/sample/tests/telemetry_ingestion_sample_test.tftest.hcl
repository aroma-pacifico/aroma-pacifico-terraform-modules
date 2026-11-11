# Native tests replace the sample provider with a mock; nothing is created.
mock_provider "aws" {
  alias           = "principal"
  override_during = plan

  mock_data "aws_caller_identity" {
    defaults = { account_id = "000000000000" }
  }

  mock_data "aws_partition" {
    defaults = { partition = "aws" }
  }

  mock_data "aws_region" {
    defaults = { region = "us-east-1" }
  }

  mock_resource "aws_iot_domain_configuration" {
    defaults = { domain_name = "ingest.example.invalid" }
  }
}

run "sample_plans_the_ingestion_boundary_with_no_secret" {
  command = plan

  assert {
    condition     = output.ingestion.environment == "pdn" && output.ingestion.topic_template == "telemetry/{thing_name}" && output.ingestion.policy_name == "fx-cf-pdn-iot-pol"
    error_message = "The sample must publish the ingestion contract of the farm module."
  }

  assert {
    condition     = output.topic_rule_arn == "arn:aws:iot:us-east-1:000000000000:rule/fx_cf_pdn_iot_rul"
    error_message = "The sample rule ARN must match the pattern the inference-functions sample allows."
  }

  assert {
    condition     = toset(keys(output.rule_catalog)) == toset(["CL-TEL-01", "CL-TEL-02"])
    error_message = "The sample must catalog the two IoT Core rows of the firewall policy."
  }
}
