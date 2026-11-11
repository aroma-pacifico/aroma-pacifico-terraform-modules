# Native tests replace the sample provider with a mock; nothing is created.
mock_provider "aws" {
  alias           = "principal"
  override_during = plan

  mock_data "aws_partition" {
    defaults = { partition = "aws" }
  }

  mock_data "aws_region" {
    defaults = { region = "us-east-1" }
  }

  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::000000000000:role/mock" }
  }

  mock_resource "aws_sqs_queue" {
    defaults = { arn = "arn:aws:sqs:us-east-1:000000000000:mock" }
  }

  mock_resource "aws_cloudwatch_log_group" {
    defaults = { arn = "arn:aws:logs:us-east-1:000000000000:log-group:mock" }
  }
}

run "four_functions_of_part_e" {
  command = plan

  assert {
    condition     = toset(keys(output.queue_arns)) == toset(["confrm", "verify", "estim", "thresh"])
    error_message = "The sample must declare the four triggers of Part E."
  }

  assert {
    condition     = toset(keys(output.dead_letter_queue_names)) == toset(["confrm", "verify", "estim", "thresh"])
    error_message = "Each function needs its own dead-letter queue."
  }

  assert {
    condition     = length(output.key_user_arns["records"]) == 4 && length(output.key_user_arns["objects"]) == 3 && length(output.key_user_arns["telemetry"]) == 1
    error_message = "Drone functions use the objects key; only the threshold function uses the telemetry key."
  }
}
