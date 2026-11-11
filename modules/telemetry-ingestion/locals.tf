locals {
  # PC-IAC-003 caps a physical name at 28 characters. The longest suffix this module appends is
  # 8 characters ("-ddb-tel"), which leaves room for the 16 character prefix.
  max_name_prefix_length = 16

  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
  region     = data.aws_region.current.region

  governance_tags = merge({
    Client      = var.client
    Project     = var.project
    Environment = var.environment
  }, var.additional_tags)

  # Physical names. Type codes (ddb, iot) differ from the function pattern codes (lmb, rol, sqs, dlq),
  # so a function key can never collide with a name here. IoT rule names allow no hyphen.
  table_name        = "${var.name_prefix}-ddb-tel"
  error_queue_name  = "${var.name_prefix}-iot-dlq"
  policy_name       = "${var.name_prefix}-iot-pol"
  domain_config     = "${var.name_prefix}-iot-dom"
  topic_rule_name   = "${replace(var.name_prefix, "-", "_")}_iot_rul"
  iot_logs_group    = "AWSIotLogsV2"
  topic_levels      = length(split("/", var.topic_namespace))
  node_topic_level  = local.topic_levels + 1
  topic_filter      = "${var.topic_namespace}/+"
  topic_template    = "${var.topic_namespace}/{thing_name}"
  retention_seconds = var.retention_days * 86400

  # The rule ARN is built from its name, not read from the resource, so a root can pass it to the queue
  # sender allowlist of the inference-functions module without a dependency cycle.
  topic_rule_arn = "arn:${local.partition}:iot:${local.region}:${local.account_id}:rule/${local.topic_rule_name}"

  # Rule SQL (version 2016-03-23 for sourceip). The derived fields come from the connection, not from the
  # device: the node comes from the topic, which the device policy ties to the certificate.
  rule_sql = join(" ", [
    "SELECT *,",
    "topic(${local.node_topic_level}) AS ${var.telemetry_attributes.node_id},",
    "timestamp() AS ${var.telemetry_attributes.received_at},",
    "floor(timestamp() / 1000) + ${local.retention_seconds} AS ${var.telemetry_attributes.expires_at},",
    "principal() AS certificate_principal,",
    "clientid() AS client_id,",
    "sourceip() AS source_ip",
    "FROM '${local.topic_filter}'",
  ])

  # IoT policy of a farm node (ADR-003, A09 section 6): connect only as its own attached thing and publish
  # only to its own topic. The policy variable is resolved by IoT Core; the doubled dollar keeps it literal.
  device_policy = {
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["iot:Connect"]
        Resource = ["arn:${local.partition}:iot:${local.region}:${local.account_id}:client/$${iot:Connection.Thing.ThingName}"]
        Condition = {
          Bool = { "iot:Connection.Thing.IsAttached" = "true" }
        }
      },
      {
        Effect   = "Allow"
        Action   = ["iot:Publish"]
        Resource = ["arn:${local.partition}:iot:${local.region}:${local.account_id}:topic/${var.topic_namespace}/$${iot:Connection.Thing.ThingName}"]
      },
    ]
  }

  # Rows of the firewall policy that this module codes (CL-TEL-01 audit, CL-TEL-02 review before production).
  rule_catalog = {
    "CL-TEL-01" = { group = "TEL", mechanism = "domain configuration", resource = "domain_configuration", validity = "permanent", audit = true }
    "CL-TEL-02" = { group = "TEL", mechanism = "domain configuration", resource = "domain_configuration", validity = "permanent", audit = false }
  }

  domain_tags = {
    AuditBeforeProduction = "true"
    FirewallRule          = "CL-TEL-01+CL-TEL-02"
    Validity              = "permanent"
  }
}
