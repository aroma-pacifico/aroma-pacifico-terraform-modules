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

  mock_data "aws_iam_policy_document" {
    defaults = { json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}" }
  }
}

variables {
  client                        = "fx"
  project                       = "cf"
  environment                   = "pdn"
  name_prefix                   = "fx-cf-pdn"
  key_administrator_arns        = ["arn:aws:iam::000000000000:role/fixture-security-apply"]
  break_glass_role_arn_patterns = ["arn:aws:iam::000000000000:role/fixture-break-glass-*"]
  key_user_arns = {
    telemetry = ["arn:aws:iam::000000000000:role/fixture-threshold-function"]
  }
}

run "keys_rotate_and_wait_30_days_before_deletion" {
  command = plan

  assert {
    condition     = length(aws_kms_key.this) == 8 && alltrue([for key in values(aws_kms_key.this) : key.enable_key_rotation && key.rotation_period_in_days == 365 && key.deletion_window_in_days == 30])
    error_message = "Every one of the eight keys must rotate every 365 days and wait 30 days before deletion."
  }

  assert {
    condition     = aws_kms_alias.this["public_view"].name == "alias/fx-cf-pdn-public-view"
    error_message = "Key aliases must follow the name prefix."
  }
}

run "key_policy_names_principals_and_protects_deletion" {
  command = plan

  assert {
    condition     = anytrue([for statement in data.aws_iam_policy_document.key["telemetry"].statement : statement.sid == "UseKey"]) && !anytrue([for statement in data.aws_iam_policy_document.key["personal"].statement : statement.sid == "UseKey"])
    error_message = "Only the class with a named user gets a use statement."
  }

  assert {
    condition = anytrue([
      for statement in data.aws_iam_policy_document.key["records"].statement :
      statement.effect == "Deny" && contains(statement.actions, "kms:ScheduleKeyDeletion") && contains(statement.actions, "kms:DisableKey") && anytrue([for condition in statement.condition : condition.test == "ArnNotLike" && contains(condition.values, "arn:aws:iam::000000000000:role/fixture-break-glass-*")])
    ])
    error_message = "Every key must deny deletion and disabling to everyone but break glass."
  }

  assert {
    condition     = anytrue([for statement in data.aws_iam_policy_document.key["logs"].statement : statement.sid == "AllowLogsService"]) && !anytrue([for statement in data.aws_iam_policy_document.key["objects"].statement : statement.sid == "AllowLogsService"])
    error_message = "Only the logs key admits the log service."
  }
}

run "staff_pool_requires_totp_and_field_pool_has_no_mfa" {
  command = plan

  assert {
    condition     = aws_cognito_user_pool.staff.mfa_configuration == "ON" && one(aws_cognito_user_pool.staff.software_token_mfa_configuration).enabled
    error_message = "The staff pool must require a TOTP second factor."
  }

  assert {
    condition     = aws_cognito_user_pool.field.mfa_configuration == "OFF"
    error_message = "The field pool must not require MFA (ASM-091)."
  }

  assert {
    condition     = output.mfa_required_roles == tolist(["agronomist", "collection_center_operator", "drone_operator", "platform_operator"])
    error_message = "MFA must cover collection_center_operator, drone_operator and platform_operator, plus the agronomist."
  }
}

run "seven_role_groups_split_across_the_two_pools" {
  command = plan

  assert {
    condition     = length(aws_cognito_user_group.this) == 7 && length(output.cognito_group_names) == 7
    error_message = "The module must plan one group per role."
  }
}

run "email_codes_only_without_an_sms_role" {
  command = plan

  assert {
    condition     = toset(one(aws_cognito_user_pool.field.sign_in_policy).allowed_first_auth_factors) == toset(["EMAIL_OTP"]) && length(aws_cognito_user_pool.field.sms_configuration) == 0
    error_message = "Without an SNS role the field pool offers email codes only."
  }
}

run "sms_codes_with_an_sns_role" {
  command = plan

  variables {
    field_sms_configuration = {
      sns_caller_arn = "arn:aws:iam::000000000000:role/fixture-cognito-sms"
      external_id    = "fixture-external-id"
    }
  }

  assert {
    condition     = contains(one(aws_cognito_user_pool.field.sign_in_policy).allowed_first_auth_factors, "SMS_OTP")
    error_message = "With an SNS role the field pool must add SMS codes."
  }
}

run "revocation_role_covers_devices_and_users" {
  command = plan

  assert {
    condition     = contains(flatten([for statement in data.aws_iam_policy_document.revocation.statement : tolist(statement.actions)]), "iot:UpdateCertificate") && contains(flatten([for statement in data.aws_iam_policy_document.revocation.statement : tolist(statement.actions)]), "iot:DetachThingPrincipal") && contains(flatten([for statement in data.aws_iam_policy_document.revocation.statement : tolist(statement.actions)]), "cognito-idp:AdminUserGlobalSignOut")
    error_message = "The revocation role must revoke certificates, detach things and end user sessions."
  }

  assert {
    condition     = !contains(flatten([for statement in data.aws_iam_policy_document.revocation.statement : tolist(statement.actions)]), "iot:DeleteCertificate")
    error_message = "The certificate is kept, revoked, for the audit trail."
  }

  assert {
    condition     = aws_iam_role.revocation.name == "fx-cf-pdn-role-revoke"
    error_message = "The revocation role must follow the name prefix."
  }
}

run "iot_rule_role_is_scoped_to_the_ingestion_resources" {
  command = plan

  assert {
    condition     = aws_iam_role.iot_rule.name == "fx-cf-pdn-role-iotrul"
    error_message = "The IoT rule role must follow the name prefix."
  }

  assert {
    condition     = one([for statement in data.aws_iam_policy_document.iot_rule.statement : statement if statement.sid == "WriteReadingToTable"]).resources == toset(["arn:aws:dynamodb:us-east-1:000000000000:table/fx-cf-pdn-ddb-tel"]) && one([for statement in data.aws_iam_policy_document.iot_rule.statement : statement if statement.sid == "WriteReadingToTable"]).actions == toset(["dynamodb:PutItem"])
    error_message = "The rule role must put items to the telemetry table only."
  }

  assert {
    condition     = one([for statement in data.aws_iam_policy_document.iot_rule.statement : statement if statement.sid == "QueueReadingAndFailures"]).resources == toset(["arn:aws:sqs:us-east-1:000000000000:fx-cf-pdn-sqs-thresh", "arn:aws:sqs:us-east-1:000000000000:fx-cf-pdn-iot-dlq"]) && one([for statement in data.aws_iam_policy_document.iot_rule.statement : statement if statement.sid == "QueueReadingAndFailures"]).actions == toset(["sqs:SendMessage"])
    error_message = "The rule role must send messages to the threshold queue and the rule error queue only."
  }

  assert {
    condition     = one([for statement in data.aws_iam_policy_document.iot_rule.statement : statement if statement.sid == "UseDataKeys"]).actions == toset(["kms:Decrypt", "kms:GenerateDataKey"])
    error_message = "The rule role must use the data keys for Decrypt and GenerateDataKey only."
  }
}

run "iot_rule_trust_names_the_service_account_and_rule" {
  command = plan

  assert {
    condition     = one(one(data.aws_iam_policy_document.iot_rule_trust.statement).principals).identifiers == toset(["iot.amazonaws.com"])
    error_message = "Only the IoT service may assume the rule role."
  }

  assert {
    condition = (
      anytrue([for condition in one(data.aws_iam_policy_document.iot_rule_trust.statement).condition : condition.variable == "aws:SourceAccount" && contains(condition.values, "000000000000")]) &&
      anytrue([for condition in one(data.aws_iam_policy_document.iot_rule_trust.statement).condition : condition.variable == "aws:SourceArn" && contains(condition.values, "arn:aws:iot:us-east-1:000000000000:rule/fx_cf_pdn_iot_rul")])
    )
    error_message = "The rule role trust must be limited to this account and to the one topic rule of the prefix."
  }
}

run "iot_logging_role_writes_only_to_the_iot_log_group" {
  command = plan

  assert {
    condition     = aws_iam_role.iot_logging.name == "fx-cf-pdn-role-iotlog"
    error_message = "The IoT logging role must follow the name prefix."
  }

  assert {
    condition     = one(data.aws_iam_policy_document.iot_logging.statement).resources == toset(["arn:aws:logs:us-east-1:000000000000:log-group:AWSIotLogsV2", "arn:aws:logs:us-east-1:000000000000:log-group:AWSIotLogsV2:log-stream:*"]) && one(data.aws_iam_policy_document.iot_logging.statement).actions == toset(["logs:CreateLogStream", "logs:DescribeLogStreams", "logs:PutLogEvents"])
    error_message = "The logging role must write only to streams of the AWSIotLogsV2 group."
  }

  assert {
    condition     = one(one(data.aws_iam_policy_document.iot_logging_trust.statement).principals).identifiers == toset(["iot.amazonaws.com"]) && anytrue([for condition in one(data.aws_iam_policy_document.iot_logging_trust.statement).condition : condition.variable == "aws:SourceAccount"])
    error_message = "Only the IoT service of this account may assume the logging role."
  }
}

run "key_policy_admits_the_rule_role_on_telemetry_and_records_only" {
  command = plan

  assert {
    condition     = anytrue([for statement in data.aws_iam_policy_document.key["records"].statement : statement.sid == "UseKey"]) && anytrue([for statement in data.aws_iam_policy_document.key["telemetry"].statement : statement.sid == "UseKey"])
    error_message = "The telemetry and records key policies must admit the rule role."
  }

  assert {
    condition     = !anytrue([for statement in data.aws_iam_policy_document.key["logs"].statement : statement.sid == "UseKey"]) && !anytrue([for statement in data.aws_iam_policy_document.key["personal"].statement : statement.sid == "UseKey"])
    error_message = "The rule role must not be admitted on the other key classes."
  }
}

run "no_secure_transport_policy_without_buckets" {
  command = plan

  assert {
    condition     = output.secure_transport_policy_statements_json == null
    error_message = "No protected bucket must render no policy."
  }
}

run "secure_transport_policy_denies_http_and_old_tls" {
  command = plan

  variables {
    protected_bucket_arns = ["arn:aws:s3:::fixture-drone-objects"]
  }

  assert {
    condition = (
      length(data.aws_iam_policy_document.secure_transport[0].statement) == 2 &&
      alltrue([for statement in data.aws_iam_policy_document.secure_transport[0].statement : statement.effect == "Deny" && contains(statement.resources, "arn:aws:s3:::fixture-drone-objects/*")]) &&
      anytrue([for statement in data.aws_iam_policy_document.secure_transport[0].statement : anytrue([for condition in statement.condition : condition.variable == "aws:SecureTransport" && contains(condition.values, "false")])]) &&
      anytrue([for statement in data.aws_iam_policy_document.secure_transport[0].statement : anytrue([for condition in statement.condition : condition.variable == "s3:TlsVersion" && contains(condition.values, "1.2")])])
    )
    error_message = "The policy must deny plain HTTP and TLS below 1.2 on the bucket and its objects."
  }
}

run "rejects_a_wildcard_key_user" {
  command = plan

  variables {
    key_user_arns = { records = ["*"] }
  }

  expect_failures = [var.key_user_arns]
}

run "rejects_an_unknown_key_class" {
  command = plan

  variables {
    key_user_arns = { payments = ["arn:aws:iam::000000000000:role/fixture"] }
  }

  expect_failures = [var.key_user_arns]
}

run "rejects_a_missing_break_glass_pattern" {
  command = plan

  variables {
    break_glass_role_arn_patterns = []
  }

  expect_failures = [var.break_glass_role_arn_patterns]
}

run "rejects_an_object_arn_as_protected_bucket" {
  command = plan

  variables {
    protected_bucket_arns = ["arn:aws:s3:::fixture-bucket/prefix/*"]
  }

  expect_failures = [var.protected_bucket_arns]
}

run "rejects_a_long_name_prefix" {
  command = plan

  variables {
    name_prefix = "fx-cf-pdn-way-too-long"
  }

  expect_failures = [var.name_prefix]
}
