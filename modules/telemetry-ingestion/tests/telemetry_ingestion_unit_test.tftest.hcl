mock_provider "aws" {
  alias           = "project"
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

  mock_resource "aws_iot_domain_configuration" {
    defaults = { domain_name = "ingest.example.invalid" }
  }
}

variables {
  client      = "fx"
  project     = "cf"
  environment = "pdn"
  name_prefix = "fx-cf-pdn"

  kms_key_arns = {
    telemetry = "arn:aws:kms:us-east-1:000000000000:key/00000000-0000-0000-0000-000000000001"
    logs      = "arn:aws:kms:us-east-1:000000000000:key/00000000-0000-0000-0000-000000000005"
  }

  rule_role_arn       = "arn:aws:iam::000000000000:role/fixture-iot-rule"
  logging_role_arn    = "arn:aws:iam::000000000000:role/fixture-iot-logging"
  threshold_queue_url = "https://sqs.us-east-1.amazonaws.com/000000000000/fx-cf-pdn-sqs-tel"

  topic_namespace     = "telemetry"
  tls_security_policy = "IoTSecurityPolicy_TLS13_1_2_2022_10"
  retention_days      = 1826
  log_retention_days  = 365
}

run "plan_builds_the_ingestion_boundary" {
  command = plan

  assert {
    condition     = aws_dynamodb_table.telemetry.hash_key == "node_id" && aws_dynamodb_table.telemetry.range_key == "reading_at" && aws_dynamodb_table.telemetry.billing_mode == "PAY_PER_REQUEST"
    error_message = "The table must be keyed by node and original reading timestamp, on demand."
  }

  assert {
    condition     = one(aws_dynamodb_table.telemetry.server_side_encryption).kms_key_arn == var.kms_key_arns["telemetry"] && one(aws_dynamodb_table.telemetry.point_in_time_recovery).enabled && aws_dynamodb_table.telemetry.deletion_protection_enabled
    error_message = "The table must use the telemetry key, point-in-time recovery and deletion protection."
  }

  assert {
    condition     = one(aws_dynamodb_table.telemetry.ttl).attribute_name == "expires_at" && one(aws_dynamodb_table.telemetry.ttl).enabled
    error_message = "The table must expire readings through the expires_at attribute."
  }

  assert {
    condition     = aws_sqs_queue.rule_errors.kms_master_key_id == var.kms_key_arns["telemetry"] && aws_sqs_queue.rule_errors.message_retention_seconds == 1209600
    error_message = "The error queue must use the telemetry key and keep messages 14 days."
  }

  assert {
    condition     = aws_cloudwatch_log_group.iot.name == "AWSIotLogsV2" && aws_cloudwatch_log_group.iot.kms_key_id == var.kms_key_arns["logs"] && aws_cloudwatch_log_group.iot.retention_in_days == 365
    error_message = "The IoT log group must be encrypted with the logs key and have a bounded retention."
  }

  assert {
    condition     = aws_iot_logging_options.this.default_log_level == "ERROR" && aws_iot_logging_options.this.role_arn == var.logging_role_arn
    error_message = "IoT Core logging must be set to ERROR with the supplied role (PD-073)."
  }

  assert {
    condition     = alltrue([for name in [aws_dynamodb_table.telemetry.name, aws_sqs_queue.rule_errors.name, aws_iot_policy.device.name, aws_iot_domain_configuration.this.name] : length(name) <= 28])
    error_message = "A physical name exceeds the 28 character cap of PC-IAC-003."
  }
}

run "device_policy_lets_a_node_connect_and_publish_only_as_itself" {
  command = plan

  assert {
    condition     = length(jsondecode(aws_iot_policy.device.policy).Statement) == 2
    error_message = "The device policy must hold exactly a connect and a publish statement."
  }

  assert {
    condition     = jsondecode(aws_iot_policy.device.policy).Statement[0].Action == ["iot:Connect"] && endswith(jsondecode(aws_iot_policy.device.policy).Statement[0].Resource[0], ":client/$${iot:Connection.Thing.ThingName}") && jsondecode(aws_iot_policy.device.policy).Statement[0].Condition.Bool["iot:Connection.Thing.IsAttached"] == "true"
    error_message = "A node must connect only with a client ID equal to its attached thing name."
  }

  assert {
    condition     = jsondecode(aws_iot_policy.device.policy).Statement[1].Action == ["iot:Publish"] && endswith(jsondecode(aws_iot_policy.device.policy).Statement[1].Resource[0], ":topic/telemetry/$${iot:Connection.Thing.ThingName}")
    error_message = "A node must publish only to its own topic."
  }

  assert {
    condition     = !strcontains(aws_iot_policy.device.policy, "iot:Subscribe") && !strcontains(aws_iot_policy.device.policy, "iot:Receive") && !strcontains(aws_iot_policy.device.policy, "\"*\"")
    error_message = "The device policy must grant no subscribe, no receive and no bare wildcard."
  }
}

run "domain_configuration_sets_the_tls_policy_and_marks_the_firewall_rows" {
  command = plan

  assert {
    condition     = one(aws_iot_domain_configuration.this.tls_config).security_policy == "IoTSecurityPolicy_TLS13_1_2_2022_10" && aws_iot_domain_configuration.this.service_type == "DATA"
    error_message = "The data endpoint must carry the TLS 1.2 minimum security policy."
  }

  assert {
    condition     = aws_iot_domain_configuration.this.tags["FirewallRule"] == "CL-TEL-01+CL-TEL-02" && aws_iot_domain_configuration.this.tags["Validity"] == "permanent" && aws_iot_domain_configuration.this.tags["AuditBeforeProduction"] == "true"
    error_message = "The domain configuration must carry the firewall rule tags."
  }

  assert {
    condition     = toset(keys(output.rule_catalog)) == toset(["CL-TEL-01", "CL-TEL-02"]) && output.rule_catalog["CL-TEL-01"].audit && !output.rule_catalog["CL-TEL-02"].audit
    error_message = "The catalog must hold CL-TEL-01 (audit) and CL-TEL-02 (review)."
  }
}

run "topic_rule_writes_queues_and_routes_failures" {
  command = plan

  assert {
    condition     = aws_iot_topic_rule.telemetry.enabled && aws_iot_topic_rule.telemetry.sql_version == "2016-03-23" && aws_iot_topic_rule.telemetry.name == "fx_cf_pdn_iot_rul"
    error_message = "The rule must be enabled, use SQL version 2016-03-23 and an underscore name."
  }

  assert {
    condition     = strcontains(aws_iot_topic_rule.telemetry.sql, "FROM 'telemetry/+'") && strcontains(aws_iot_topic_rule.telemetry.sql, "topic(2) AS node_id") && strcontains(aws_iot_topic_rule.telemetry.sql, "principal() AS certificate_principal") && strcontains(aws_iot_topic_rule.telemetry.sql, "clientid() AS client_id") && strcontains(aws_iot_topic_rule.telemetry.sql, "sourceip() AS source_ip") && strcontains(aws_iot_topic_rule.telemetry.sql, "timestamp() AS iot_received_at")
    error_message = "The rule SQL must derive the node and the audit fields from the connection."
  }

  assert {
    condition     = strcontains(aws_iot_topic_rule.telemetry.sql, "floor(timestamp() / 1000) + 157766400 AS expires_at")
    error_message = "The expiry must be the receive time in seconds plus 1826 days."
  }

  assert {
    condition     = !strcontains(lower(aws_iot_topic_rule.telemetry.sql), "where")
    error_message = "Thresholds are data and must not appear in the rule SQL."
  }

  assert {
    condition     = one(aws_iot_topic_rule.telemetry.dynamodbv2).role_arn == var.rule_role_arn && one(one(aws_iot_topic_rule.telemetry.dynamodbv2).put_item).table_name == "fx-cf-pdn-ddb-tel"
    error_message = "The rule must write each reading to the telemetry table with the supplied role."
  }

  assert {
    condition     = one(aws_iot_topic_rule.telemetry.sqs).queue_url == var.threshold_queue_url && !one(aws_iot_topic_rule.telemetry.sqs).use_base64
    error_message = "The rule must send each reading to the threshold queue."
  }

  assert {
    condition     = one(one(aws_iot_topic_rule.telemetry.error_action).sqs).role_arn == var.rule_role_arn && length(aws_iot_topic_rule.telemetry.lambda) == 0
    error_message = "A failed action must go to the error queue, and no function is invoked directly."
  }
}

run "outputs_fit_the_farm_module_and_the_function_module" {
  command = plan

  assert {
    condition     = toset(keys(output.ingestion)) == toset(["environment", "endpoint", "policy_name", "topic_template"]) && output.ingestion.environment == "pdn" && output.ingestion.topic_template == "telemetry/{thing_name}"
    error_message = "The ingestion output must have the shape of the farm module input."
  }

  assert {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9.-]*[A-Za-z0-9]$", output.ingestion.endpoint)) && can(regex("^[A-Za-z0-9_-]{1,128}$", output.ingestion.policy_name))
    error_message = "The endpoint and policy name must pass the validations of the farm module."
  }

  assert {
    condition     = output.topic_rule_arn == "arn:aws:iot:us-east-1:000000000000:rule/fx_cf_pdn_iot_rul"
    error_message = "The rule ARN must be built from the rule name."
  }

  assert {
    condition     = output.topic_filter == "telemetry/+" && output.item_attributes.reading_at_type == "S"
    error_message = "The topic filter and item attributes must follow the inputs."
  }
}

run "multi_level_namespace_moves_the_node_level" {
  command = plan

  variables {
    topic_namespace = "farm/telemetry"
  }

  assert {
    condition     = strcontains(aws_iot_topic_rule.telemetry.sql, "topic(3) AS node_id") && output.topic_template == "farm/telemetry/{thing_name}"
    error_message = "A two-level namespace must read the node from the third topic level."
  }
}

run "numeric_reading_timestamp_changes_the_sort_key_type" {
  command = plan

  variables {
    telemetry_attributes = { reading_at_type = "N" }
  }

  assert {
    condition     = one([for attribute in aws_dynamodb_table.telemetry.attribute : attribute if attribute.name == "reading_at"]).type == "N"
    error_message = "The sort key type must follow reading_at_type."
  }
}

run "rejects_a_tls_policy_below_1_2" {
  command = plan

  variables {
    tls_security_policy = "IoTSecurityPolicy_TLS12_1_0_2016_01"
  }

  expect_failures = [var.tls_security_policy]
}

run "rejects_a_name_prefix_over_16_characters" {
  command = plan

  variables {
    name_prefix = "fx-cf-pdn-extra-long"
  }

  expect_failures = [var.name_prefix]
}

run "rejects_a_wildcard_topic_namespace" {
  command = plan

  variables {
    topic_namespace = "telemetry/#"
  }

  expect_failures = [var.topic_namespace]
}

run "rejects_an_attribute_that_reuses_an_audit_field" {
  command = plan

  variables {
    telemetry_attributes = { node_id = "client_id" }
  }

  expect_failures = [var.telemetry_attributes]
}

run "rejects_a_role_that_is_not_an_iam_role" {
  command = plan

  variables {
    rule_role_arn = "arn:aws:iam::000000000000:user/fixture-user"
  }

  expect_failures = [var.rule_role_arn]
}

run "rejects_a_queue_that_is_not_an_sqs_url" {
  command = plan

  variables {
    threshold_queue_url = "arn:aws:sqs:us-east-1:000000000000:fx-cf-pdn-sqs-tel"
  }

  expect_failures = [var.threshold_queue_url]
}

run "rejects_log_retention_that_never_expires" {
  command = plan

  variables {
    log_retention_days = 0
  }

  expect_failures = [var.log_retention_days]
}

run "rejects_missing_key_classes" {
  command = plan

  variables {
    kms_key_arns = { telemetry = "arn:aws:kms:us-east-1:000000000000:key/00000000-0000-0000-0000-000000000001" }
  }

  expect_failures = [var.kms_key_arns]
}
