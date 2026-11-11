# The consuming root supplies aws.project; child modules configure no providers.
mock_provider "aws" {
  alias           = "project"
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

variables {
  client             = "fx"
  project            = "cf"
  environment        = "pdn"
  name_prefix        = "fx-cf-pdn"
  log_retention_days = 365
  kms_key_arns = {
    telemetry  = "arn:aws:kms:us-east-1:000000000000:key/telemetry"
    objects    = "arn:aws:kms:us-east-1:000000000000:key/objects"
    records    = "arn:aws:kms:us-east-1:000000000000:key/records"
    personal   = "arn:aws:kms:us-east-1:000000000000:key/personal"
    logs       = "arn:aws:kms:us-east-1:000000000000:key/logs"
    restricted = "arn:aws:kms:us-east-1:000000000000:key/restricted"
  }
  functions = {
    confrm = {
      description = "Confirmation fixture."
      package     = { filename = "build/placeholder.zip" }
      inference   = { model_id = "amazon.nova-pro-v1:0" }
      read = {
        s3_object_arns      = ["arn:aws:s3:::fixture-drone-objects/farms/*"]
        dynamodb_table_arns = ["arn:aws:dynamodb:us-east-1:000000000000:table/fixture-missions"]
        kms_classes         = ["objects"]
      }
      write = {
        dynamodb_table_arns = ["arn:aws:dynamodb:us-east-1:000000000000:table/fixture-missions"]
        kms_classes         = ["records"]
      }
      queue_senders = {
        service_principals = ["events.amazonaws.com"]
        source_arns        = ["arn:aws:events:us-east-1:000000000000:rule/fixture/*"]
      }
    }
    thresh = {
      description          = "Threshold fixture."
      package              = { filename = "build/placeholder.zip" }
      timeout_seconds      = 60
      memory_mb            = 256
      batch_size           = 10
      reserved_concurrency = 10
      backoff_base_seconds = 10
      inference            = { model_id = "amazon.nova-pro-v1:0" }
      read = {
        dynamodb_table_arns = ["arn:aws:dynamodb:us-east-1:000000000000:table/fixture-telemetry"]
        kms_classes         = ["telemetry"]
      }
      write = {
        dynamodb_table_arns = ["arn:aws:dynamodb:us-east-1:000000000000:table/fixture-alerts"]
        sns_topic_arns      = ["arn:aws:sns:us-east-1:000000000000:fixture-alerts"]
        kms_classes         = ["records"]
      }
    }
  }
}

# Criterion 1: trigger, read permission, invocation and result write.
run "pattern_has_trigger_read_write_and_invoke" {
  command = plan

  assert {
    condition     = alltrue([for key in ["confrm", "thresh"] : aws_lambda_event_source_mapping.this[key].function_response_types == toset(["ReportBatchItemFailures"])])
    error_message = "Each function needs an SQS event source mapping with partial batch responses."
  }

  assert {
    condition     = aws_lambda_event_source_mapping.this["thresh"].batch_size == 10 && aws_lambda_event_source_mapping.this["confrm"].batch_size == 1
    error_message = "Batch size must follow the design values: 1 mission, 10 readings."
  }

  assert {
    condition     = contains(flatten([for s in local.policy_statements["confrm"] : s.Action if s.Sid == "ReadPersistedObjects"]), "s3:GetObjectVersion")
    error_message = "The drone function must read the persisted object by version."
  }

  assert {
    condition     = contains(flatten([for s in local.policy_statements["confrm"] : s.Action if s.Sid == "WriteResultRecord"]), "dynamodb:ConditionCheckItem")
    error_message = "The result write must support the conditional transaction."
  }

  assert {
    condition     = flatten([for s in local.policy_statements["confrm"] : s.Resource if s.Sid == "InvokeOneFoundationModel"]) == ["arn:aws:bedrock:us-east-1::foundation-model/amazon.nova-pro-v1:0"]
    error_message = "Inference is permitted on one foundation model ARN only, with no inference profile."
  }

  assert {
    condition     = length([for s in local.policy_statements["thresh"] : s if s.Sid == "ReadPersistedObjects"]) == 0 && length([for s in local.policy_statements["thresh"] : s if s.Sid == "PublishAlerts"]) == 1
    error_message = "A grant that is not declared adds no statement; the threshold function publishes alerts and reads no object."
  }

  assert {
    condition     = alltrue([for key in ["confrm", "thresh"] : alltrue([for s in local.policy_statements[key] : !contains(s.Resource, "*") || s.Effect == "Deny"])])
    error_message = "Only an explicit Deny may use a wildcard resource."
  }
}

# Criterion 2: timestamp, confidence and source object identifier.
run "result_contract_reaches_the_function" {
  command = plan

  assert {
    condition     = aws_lambda_function.this["confrm"].environment[0].variables["RESULT_TIMESTAMP_ATTRIBUTE"] == "result_at" && aws_lambda_function.this["confrm"].environment[0].variables["RESULT_CONFIDENCE_ATTRIBUTE"] == "confidence" && aws_lambda_function.this["confrm"].environment[0].variables["RESULT_SOURCE_OBJECT_ATTRIBUTE"] == "source"
    error_message = "The three result attribute names must reach the function."
  }

  assert {
    condition     = output.result_record_attributes.timestamp == "result_at" && output.result_record_attributes.confidence == "confidence" && output.result_record_attributes.source_object == "source"
    error_message = "The module must expose the result record contract."
  }
}

# Criterion 3: retries and dead-letter queue.
run "retries_and_dead_letter_queue" {
  command = plan

  assert {
    condition     = aws_sqs_queue.this["confrm"].visibility_timeout_seconds == 1800 && aws_sqs_queue.this["thresh"].visibility_timeout_seconds == 360
    error_message = "Visibility timeout must be six times the function timeout (1,800 s and 360 s)."
  }

  assert {
    condition     = jsondecode(aws_sqs_queue.this["confrm"].redrive_policy).maxReceiveCount == 5
    error_message = "A message moves to the dead-letter queue after 5 receives."
  }

  assert {
    condition     = aws_sqs_queue.dead_letter["confrm"].message_retention_seconds == 1209600 && aws_sqs_queue.dead_letter["confrm"].kms_master_key_id == var.kms_key_arns["records"]
    error_message = "The dead-letter queue keeps messages 14 days and is encrypted with the records key."
  }

  assert {
    condition     = aws_lambda_function.this["thresh"].environment[0].variables["BACKOFF_BASE_SECONDS"] == "10" && aws_lambda_function.this["confrm"].environment[0].variables["BACKOFF_BASE_SECONDS"] == "60"
    error_message = "The backoff base must reach the function."
  }
}

# Criterion 4: no persistent compute waiting for objects. The module declares only the Lambda
# function and its event source mapping as compute; the function is invoked per message.
run "no_persistent_compute" {
  command = plan

  assert {
    condition     = alltrue([for f in aws_lambda_function.this : f.reserved_concurrent_executions != null && f.reserved_concurrent_executions >= 1])
    error_message = "Concurrency is bounded by reserved concurrency; no provisioned concurrency is declared."
  }

  assert {
    condition     = alltrue([for m in aws_lambda_event_source_mapping.this : m.maximum_batching_window_in_seconds == 0])
    error_message = "Messages are delivered as they arrive; nothing waits for objects."
  }
}

# Key separation: personal and restricted keys are never granted and are explicitly denied.
run "personal_and_restricted_keys_are_denied" {
  command = plan

  assert {
    condition     = flatten([for s in local.policy_statements["confrm"] : s.Resource if s.Sid == "NeverUsePersonalOrRestrictedKeys"]) == [var.kms_key_arns["personal"], var.kms_key_arns["restricted"]]
    error_message = "The role must carry an explicit deny on the personal and restricted keys."
  }

  assert {
    condition     = !contains(flatten([for s in local.policy_statements["confrm"] : s.Resource if s.Effect == "Allow"]), var.kms_key_arns["personal"])
    error_message = "The personal key must never be granted."
  }

  assert {
    condition     = contains(flatten([for s in local.policy_statements["confrm"] : s.Action if s.Sid == "NeverWriteObjects"]), "s3:PutObject")
    error_message = "The role must carry an explicit deny on object writes."
  }
}

run "key_user_arns_follow_the_security_module_shape" {
  command = plan

  assert {
    condition     = length(output.key_user_arns["objects"]) == 1 && length(output.key_user_arns["records"]) == 2 && length(output.key_user_arns["telemetry"]) == 1 && !contains(keys(output.key_user_arns), "personal")
    error_message = "key_user_arns must list the function roles per key class and never the personal class."
  }
}

run "names_stay_within_28_characters" {
  command = plan

  assert {
    condition     = alltrue([for key, n in local.names : alltrue([for name in values(n) : length(name) <= 28])])
    error_message = "Physical names must not exceed 28 characters (PC-IAC-003)."
  }
}

run "rejects_personal_key_class" {
  command = plan

  variables {
    functions = {
      confrm = {
        description = "Bad fixture."
        package     = { filename = "build/placeholder.zip" }
        inference   = { model_id = "amazon.nova-pro-v1:0" }
        read        = { kms_classes = ["personal"] }
      }
    }
  }

  expect_failures = [var.functions]
}

run "rejects_inference_profile_identifier" {
  command = plan

  variables {
    functions = {
      confrm = {
        description = "Bad fixture."
        package     = { filename = "build/placeholder.zip" }
        inference   = { model_id = "us.amazon.nova-pro-v1:0" }
      }
    }
  }

  expect_failures = [var.functions]
}

run "rejects_wildcard_permission_target" {
  command = plan

  variables {
    functions = {
      confrm = {
        description = "Bad fixture."
        package     = { filename = "build/placeholder.zip" }
        inference   = { model_id = "amazon.nova-pro-v1:0" }
        read        = { s3_object_arns = ["arn:aws:s3:::*/*"] }
      }
    }
  }

  expect_failures = [var.functions]
}
