output "certificate_arns" {
  description = "Child certificate references for root consumers."
  value       = module.farm.certificate_arns
}

output "ingestion_endpoint" {
  description = "Child ingestion connection point."
  value       = module.farm.ingestion_endpoint
}

output "node_names" {
  description = "Child identities without copied resource logic."
  value       = module.farm.node_names
}

output "telemetry_topics" {
  description = "Child publish destinations without duplicated topic rendering."
  value       = module.farm.telemetry_topics
}
