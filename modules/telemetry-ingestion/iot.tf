# Device policy (A09 section 6): one policy for every farm node, written with a policy variable so that no
# policy names a device. The farm module attaches it to each certificate; nothing here attaches it.
resource "aws_iot_policy" "device" {
  provider = aws.project

  name   = local.policy_name
  policy = jsonencode(local.device_policy)

  tags = merge(local.governance_tags, { Name = local.policy_name })
}

# CL-TEL-01 and CL-TEL-02: the data endpoint nodes connect to, with a TLS 1.2 minimum policy. The default
# application protocol and authentication type admit MQTT over TLS with an X.509 client certificate on
# port 8883 and on port 443 with ALPN.
resource "aws_iot_domain_configuration" "this" {
  provider = aws.project

  name         = local.domain_config
  service_type = "DATA"
  status       = "ENABLED"

  tls_config {
    security_policy = var.tls_security_policy
  }

  tags = merge(local.governance_tags, local.domain_tags, { Name = local.domain_config })
}

# Account-level IoT Core logging at ERROR (PD-073). IoT Core allows one such setting per Region, so one
# ingestion module serves one account and Region.
resource "aws_iot_logging_options" "this" {
  provider = aws.project

  default_log_level = "ERROR"
  role_arn          = var.logging_role_arn

  depends_on = [aws_cloudwatch_log_group.iot]
}

# Routing rule (ADR-003, ASM-161): every reading on the telemetry topic is written to the table and sent
# to the threshold queue; a failed action sends the message to the error queue. Thresholds are data read by
# the function, never rule SQL.
resource "aws_iot_topic_rule" "telemetry" {
  provider = aws.project

  description = "Writes each telemetry reading to the table and queues it for the threshold function"
  enabled     = true
  name        = local.topic_rule_name
  sql         = local.rule_sql
  sql_version = "2016-03-23"

  dynamodbv2 {
    role_arn = var.rule_role_arn

    put_item {
      table_name = aws_dynamodb_table.telemetry.name
    }
  }

  sqs {
    queue_url  = var.threshold_queue_url
    role_arn   = var.rule_role_arn
    use_base64 = false
  }

  error_action {
    sqs {
      queue_url  = aws_sqs_queue.rule_errors.url
      role_arn   = var.rule_role_arn
      use_base64 = false
    }
  }

  tags = merge(local.governance_tags, { Name = local.topic_rule_name })
}
