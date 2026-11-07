# Deliberate public integration references, never whole resources or private keys.
output "certificate_arns" {
  description = "Public certificate references by node role; no private keys or PEM material."
  value       = { for role, certificate in aws_iot_certificate.node : role => certificate.arn }
}

output "desired_cost_tags" {
  description = "Requested cost metadata only; not AWS tags applied to the unsupported IoT resource types."
  value       = local.desired_cost_tags
}

output "ingestion_endpoint" {
  description = "Injected environment IoT endpoint for both live and drained readings; existence is not verified here."
  value       = var.ingestion.endpoint
}

output "node_names" {
  description = "Stable registry names and MQTT client identifiers for the two node roles."
  value       = { for role, node in aws_iot_thing.node : role => node.name }
}

output "store_and_forward_contract" {
  description = "A10 integration requirements, not implemented buffering, retries, latency, or delivery guarantees."
  value = {
    protocol                  = "MQTT over TLS", minimum_tls_version = "1.2", qos = 1,
    maximum_buffer_hours      = 24, release_on = "PUBACK",
    required_message_metadata = ["node identity", "original reading timestamp", "sequence number", "measurement values"]
  }
}

output "telemetry_topics" {
  description = "Own-node publish destinations rendered from the supplied ingestion topic contract."
  value       = local.telemetry_topics
}
