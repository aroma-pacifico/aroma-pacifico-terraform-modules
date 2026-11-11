output "availability_zone_ids" {
  description = "Availability Zone ID behind each slot (az1 to az3), chosen by the module in sorted order."
  value       = local.az_ids
}

output "internet_gateway_id" {
  description = "ID of the internet gateway, routed only from public_query."
  value       = aws_internet_gateway.this.id
}

output "route_table_ids" {
  description = "Route table ID of each tier, for later routes and associations."
  value       = { for tier, route_table in aws_route_table.this : tier => route_table.id }
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

output "transit_attachment_subnet_ids" {
  description = "Subnets of the transit tier, one per Availability Zone slot, for the transit gateway VPC attachment created outside this module."
  value       = [for az in local.az_slots : aws_subnet.this["transit-${az}"].id]
}

output "vpc_cidr_block" {
  description = "Primary IPv4 CIDR block of the environment VPC."
  value       = aws_vpc.this.cidr_block
}

output "vpc_id" {
  description = "ID of the environment VPC."
  value       = aws_vpc.this.id
}
