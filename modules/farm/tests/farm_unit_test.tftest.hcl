mock_provider "aws" {
  alias           = "project"
  override_during = plan
  mock_resource "aws_iot_certificate" {
    defaults = { private_key = "", public_key = "" }
  }
}

variables {
  client      = "fx"
  project     = "cf"
  environment = "qa"
  farm_id     = "fixture-a"
  name_prefix = "fx-cf-qa-iot-a"
  nodes = {
    crop   = { csr = file("tests/fixtures/crop.csr") }
    drying = { csr = file("tests/fixtures/drying.csr") }
  }
  ingestion = {
    environment = "qa", endpoint = "ingestion.example.invalid",
    policy_name = "fixture-policy", topic_template = "fixture/{thing_name}"
  }
}

run "farm_a" {
  command = plan
  assert {
    condition     = output.node_names == { crop = "fx-cf-qa-iot-a-crop", drying = "fx-cf-qa-iot-a-drying" }
    error_message = "One farm must expose exactly its crop and drying node identities."
  }
  assert {
    condition     = length(aws_iot_thing.node) == 2 && length(aws_iot_certificate.node) == 2 && length(aws_iot_thing_principal_attachment.node) == 2 && length(aws_iot_policy_attachment.node) == 2
    error_message = "The single-farm plan must contain exactly eight cloud identity resources."
  }
  assert {
    condition     = output.telemetry_topics.crop == "fixture/fx-cf-qa-iot-a-crop" && output.ingestion_endpoint == var.ingestion.endpoint && length(output.certificate_arns) == 2
    error_message = "Connection points must use the selected farm and injected ingestion references."
  }
  assert {
    condition     = alltrue([for role, attachment in aws_iot_thing_principal_attachment.node : attachment.thing == aws_iot_thing.node[role].name && attachment.principal == aws_iot_certificate.node[role].arn]) && alltrue([for role, attachment in aws_iot_policy_attachment.node : attachment.target == aws_iot_certificate.node[role].arn && attachment.policy == var.ingestion.policy_name])
    error_message = "Each node must attach its own certificate and the supplied policy."
  }
  assert {
    condition     = alltrue([for role, certificate in aws_iot_certificate.node : certificate.csr == var.nodes[role].csr && certificate.active && certificate.private_key == ""])
    error_message = "Every certificate must use its public CSR; mocked private keys must stay empty."
  }
  assert {
    condition     = output.store_and_forward_contract.maximum_buffer_hours == 24 && output.store_and_forward_contract.qos == 1 && output.store_and_forward_contract.release_on == "PUBACK"
    error_message = "The integration contract must preserve A10's buffer and acknowledgement requirements."
  }
}

run "farm_b" {
  command = plan
  variables {
    farm_id     = "fixture-b"
    name_prefix = "fx-cf-qa-iot-b"
  }
  assert {
    condition     = aws_iot_thing.node["crop"].attributes.FarmId == "fixture-b" && output.node_names.crop == "fx-cf-qa-iot-b-crop" && length(aws_iot_thing.node) == 2
    error_message = "Another farm must use the same interface without adding the previous farm."
  }
}

run "dev_isolation" {
  command = plan
  variables {
    environment = "dev"
    name_prefix = "fx-cf-dev-iot-a"
    ingestion = {
      environment = "dev", endpoint = "dev.example.invalid",
      policy_name = "fixture-dev-policy", topic_template = "fixture/{thing_name}"
    }
  }
  assert {
    condition     = output.node_names.crop == "fx-cf-dev-iot-a-crop" && output.ingestion_endpoint == "dev.example.invalid" && aws_iot_thing.node["crop"].attributes.Environment == "dev"
    error_message = "Environment context must propagate to names, metadata and ingestion connection points."
  }
}

run "blank_farm" {
  command = plan
  variables { farm_id = " " }
  expect_failures = [var.farm_id]
}

run "invalid_environment" {
  command = plan
  variables {
    environment = "staging"
    name_prefix = "fx-cf-staging-iot-a"
    ingestion = {
      environment = "staging", endpoint = "ingestion.example.invalid",
      policy_name = "fixture-policy", topic_template = "fixture/{thing_name}"
    }
  }
  expect_failures = [var.environment]
}

run "cross_environment_ingestion" {
  command = plan
  variables {
    ingestion = {
      environment = "pdn", endpoint = "ingestion.example.invalid",
      policy_name = "fixture-policy", topic_template = "fixture/{thing_name}"
    }
  }
  expect_failures = [var.ingestion]
}

run "cross_environment_name" {
  command = plan
  variables { name_prefix = "fx-cf-pdn-iot-a" }
  expect_failures = [var.name_prefix]
}

run "missing_policy" {
  command = plan
  variables {
    ingestion = {
      environment = "qa", endpoint = "ingestion.example.invalid",
      policy_name = "", topic_template = "fixture/{thing_name}"
    }
  }
  expect_failures = [var.ingestion]
}

run "invalid_endpoint" {
  command = plan
  variables {
    ingestion = {
      environment = "qa", endpoint = "http://ingestion.example.invalid/path",
      policy_name = "fixture-policy", topic_template = "fixture/{thing_name}"
    }
  }
  expect_failures = [var.ingestion]
}

run "wildcard_topic" {
  command = plan
  variables {
    ingestion = {
      environment = "qa", endpoint = "ingestion.example.invalid",
      policy_name = "fixture-policy", topic_template = "fixture/{thing_name}/#"
    }
  }
  expect_failures = [var.ingestion]
}

run "missing_own_node_topic" {
  command = plan
  variables {
    ingestion = {
      environment = "qa", endpoint = "ingestion.example.invalid",
      policy_name = "fixture-policy", topic_template = "fixture/other-node"
    }
  }
  expect_failures = [var.ingestion]
}

run "invalid_csr" {
  command = plan
  variables {
    nodes = {
      crop   = { csr = "invalid" }
      drying = { csr = file("tests/fixtures/drying.csr") }
    }
  }
  expect_failures = [var.nodes]
}

run "duplicate_csr" {
  command = plan
  variables {
    nodes = {
      crop   = { csr = file("tests/fixtures/crop.csr") }
      drying = { csr = file("tests/fixtures/crop.csr") }
    }
  }
  expect_failures = [var.nodes]
}

run "multiple_farms_as_nodes" {
  command = plan
  variables {
    nodes = { farm_a = { csr = file("tests/fixtures/crop.csr") }, farm_b = { csr = file("tests/fixtures/drying.csr") } }
  }
  expect_failures = [var.nodes]
}

run "duplicate_csr_line_endings" {
  command = plan
  variables {
    nodes = {
      crop   = { csr = replace(file("tests/fixtures/crop.csr"), "\r\n", "\n") }
      drying = { csr = replace(replace(file("tests/fixtures/crop.csr"), "\r\n", "\n"), "\n", "\r\n") }
    }
  }
  expect_failures = [var.nodes]
}

run "duplicate_csr_trailing_whitespace" {
  command = plan
  variables {
    nodes = {
      crop   = { csr = file("tests/fixtures/crop.csr") }
      drying = { csr = "${file("tests/fixtures/crop.csr")}\n " }
    }
  }
  expect_failures = [var.nodes]
}
