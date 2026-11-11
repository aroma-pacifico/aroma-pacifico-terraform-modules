output "interface_endpoint_ids" {
  description = "Interface endpoint IDs keyed by short name."
  value       = module.network.interface_endpoint_ids
}

output "network_acl_ids" {
  description = "Network ACL ID of each tier."
  value       = module.network.network_acl_ids
}

output "route_table_ids" {
  description = "Route table ID of each tier."
  value       = module.network.route_table_ids
}

output "subnet_ids" {
  description = "Subnet IDs keyed by tier and Availability Zone slot."
  value       = module.network.subnet_ids
}

output "vpc_id" {
  description = "ID of the environment VPC."
  value       = module.network.vpc_id
}
