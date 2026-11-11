output "device_policy_name" {
  description = "Name of the IoT policy that the farm module attaches to each node certificate."
  value       = module.telemetry_ingestion.device_policy_name
}

output "ingestion" {
  description = "Ingestion contract in the shape of the farm module input."
  value       = module.telemetry_ingestion.ingestion
}

output "rule_catalog" {
  description = "Firewall policy rows coded by the module."
  value       = module.telemetry_ingestion.rule_catalog
}

output "telemetry_table_arn" {
  description = "ARN of the telemetry table."
  value       = module.telemetry_ingestion.telemetry_table_arn
}

output "topic_rule_arn" {
  description = "ARN of the telemetry topic rule."
  value       = module.telemetry_ingestion.topic_rule_arn
}
