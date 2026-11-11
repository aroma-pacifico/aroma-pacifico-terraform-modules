output "availability_zone_ids" {
  description = "Availability Zone ID behind each slot (az1 to az3), chosen by the module in sorted order."
  value       = local.az_ids
}

output "subnet_cidr_blocks" {
  description = "Subnet CIDR blocks keyed by tier and then by Availability Zone slot."
  value       = var.subnets
}

output "subnet_ids" {
  description = "Subnet IDs keyed by tier and then by Availability Zone slot, for later routes, endpoints and associations."
  value = {
    for tier, azs in var.subnets : tier => {
      for az in keys(azs) : az => aws_subnet.this["${tier}-${az}"].id
    }
  }
}

output "vpc_cidr_block" {
  description = "Primary IPv4 CIDR block of the environment VPC."
  value       = aws_vpc.this.cidr_block
}

output "vpc_id" {
  description = "ID of the environment VPC."
  value       = aws_vpc.this.id
}
