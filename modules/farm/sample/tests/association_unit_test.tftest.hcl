mock_provider "aws" {
  alias           = "principal"
  override_during = plan
  mock_resource "aws_iot_certificate" {
    defaults = { private_key = "", public_key = "" }
  }
}

run "qa_association" {
  command = plan
  assert {
    condition     = output.node_names.crop == "fx-cf-qa-iot-a-crop" && output.ingestion_endpoint == "ingestion.example.invalid" && length(output.certificate_arns) == 2
    error_message = "The qa example must invoke exactly one farm module and expose its connections."
  }
}

run "dev_association" {
  command = plan
  variables {
    environment = "dev"
    farm_id     = "fixture-b"
    farm_key    = "b"
    ingestion = {
      environment = "dev", endpoint = "dev.example.invalid",
      policy_name = "fixture-dev-policy", topic_template = "fixture/{thing_name}"
    }
  }
  assert {
    condition     = output.node_names.crop == "fx-cf-dev-iot-b-crop" && output.telemetry_topics.drying == "fixture/fx-cf-dev-iot-b-drying" && output.ingestion_endpoint == "dev.example.invalid"
    error_message = "The same child must work in dev without copying resource logic or qa destinations."
  }
}
