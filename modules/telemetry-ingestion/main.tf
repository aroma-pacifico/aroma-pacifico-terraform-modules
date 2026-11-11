# Telemetry store (ADR-003): one item per reading, keyed by node and original reading timestamp, so a
# reading published twice (QoS 1 redelivery, drain after a lost PUBACK) is stored once.
resource "aws_dynamodb_table" "telemetry" {
  provider = aws.project

  billing_mode                = "PAY_PER_REQUEST"
  deletion_protection_enabled = true
  hash_key                    = var.telemetry_attributes.node_id
  name                        = local.table_name
  range_key                   = var.telemetry_attributes.reading_at

  attribute {
    name = var.telemetry_attributes.node_id
    type = "S"
  }

  attribute {
    name = var.telemetry_attributes.reading_at
    type = var.telemetry_attributes.reading_at_type
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arns["telemetry"]
  }

  ttl {
    attribute_name = var.telemetry_attributes.expires_at
    enabled        = true
  }

  tags = merge(local.governance_tags, { Name = local.table_name })

  lifecycle {
    prevent_destroy = true
  }
}

# Error action queue of the topic rule. It keeps the readings that a rule action could not deliver, so
# they can be replayed into the table, which is idempotent by key.
resource "aws_sqs_queue" "rule_errors" {
  provider = aws.project

  kms_master_key_id         = var.kms_key_arns["telemetry"]
  message_retention_seconds = var.error_queue_retention_days * 86400
  name                      = local.error_queue_name

  tags = merge(local.governance_tags, { Name = local.error_queue_name })
}

resource "aws_sqs_queue_policy" "rule_errors" {
  provider = aws.project

  queue_url = aws_sqs_queue.rule_errors.url

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyPlainHttp"
      Effect    = "Deny"
      Principal = "*"
      Action    = "sqs:*"
      Resource  = aws_sqs_queue.rule_errors.arn
      Condition = {
        Bool = { "aws:SecureTransport" = "false" }
      }
    }]
  })
}

# AWS IoT Core writes rejected connections and publishes here once logging is on (PD-073). Creating the
# group first lets the module encrypt it with the logs key and bound its retention.
resource "aws_cloudwatch_log_group" "iot" {
  provider = aws.project

  kms_key_id        = var.kms_key_arns["logs"]
  name              = local.iot_logs_group
  retention_in_days = var.log_retention_days

  tags = merge(local.governance_tags, { Name = local.iot_logs_group })
}
