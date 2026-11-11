output "device_policy_arn" {
  description = "ARN of the IoT policy of a farm node."
  value       = aws_iot_policy.device.arn
}

output "device_policy_name" {
  description = "Name of the IoT policy of a farm node, which the farm module attaches to each node certificate."
  value       = aws_iot_policy.device.name
}

output "domain_configuration_name" {
  description = "Name of the IoT Core domain configuration that carries the TLS policy."
  value       = aws_iot_domain_configuration.this.name
}

output "endpoint" {
  description = "Hostname of the IoT Core data endpoint that farm nodes connect to over MQTT with TLS, without scheme or port. The same endpoint serves 200 or 1,000 farms."
  value       = aws_iot_domain_configuration.this.domain_name
}

output "error_queue_arn" {
  description = "ARN of the rule error queue."
  value       = aws_sqs_queue.rule_errors.arn
}

output "error_queue_name" {
  description = "Name of the rule error queue, for the alarm on its first message."
  value       = aws_sqs_queue.rule_errors.name
}

output "error_queue_url" {
  description = "URL of the rule error queue, for the replay of failed readings."
  value       = aws_sqs_queue.rule_errors.url
}

output "ingestion" {
  description = "Same-environment ingestion contract in the shape of the ingestion input of the farm module: environment, endpoint, policy_name and topic_template."
  value = {
    environment    = var.environment
    endpoint       = aws_iot_domain_configuration.this.domain_name
    policy_name    = aws_iot_policy.device.name
    topic_template = local.topic_template
  }
}

output "item_attributes" {
  description = "Attribute names of a stored reading: node_id, reading_at, reading_at_type, received_at and expires_at. The first two are the table key."
  value       = var.telemetry_attributes
}

output "log_group_name" {
  description = "Name of the IoT Core log group."
  value       = aws_cloudwatch_log_group.iot.name
}

output "rule_catalog" {
  description = "Rows of the firewall policy table that this module codes, keyed by policy ID, with group, mechanism, validity and whether the row is audited before production (PD-125)."
  value       = local.rule_catalog
}

output "telemetry_table_arn" {
  description = "ARN of the telemetry table, for the read permission of the threshold function."
  value       = aws_dynamodb_table.telemetry.arn
}

output "telemetry_table_name" {
  description = "Name of the telemetry table."
  value       = aws_dynamodb_table.telemetry.name
}

output "topic_filter" {
  description = "MQTT topic filter that the topic rule subscribes to."
  value       = local.topic_filter
}

output "topic_rule_arn" {
  description = "ARN of the telemetry topic rule, built from its name so that a root can pass it to the queue senders of the inference-functions module without a dependency cycle."
  value       = local.topic_rule_arn
}

output "topic_rule_name" {
  description = "Name of the telemetry topic rule."
  value       = local.topic_rule_name
}

output "topic_template" {
  description = "Topic a node publishes to, with one {thing_name} placeholder that the farm module fills with the node name."
  value       = local.topic_template
}
