output "subnet_ids" {
  description = "Subnet IDs keyed by tier and Availability Zone slot."
  value       = module.network.subnet_ids
}

output "vpc_id" {
  description = "ID of the environment VPC."
  value       = module.network.vpc_id
}
