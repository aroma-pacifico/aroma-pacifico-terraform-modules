output "vpc_attachment_id" {
  description = "Workload VPC attachment reference for B07 association and static routes."
  value       = aws_ec2_transit_gateway_vpc_attachment.environment.id
}
output "vpn_connection_id" {
  description = "Selected center VPN reference; two tunnels are implicit in this one connection."
  value       = aws_vpn_connection.center.id
}
output "vpn_attachment_id" {
  description = "Hub-owned VPN attachment for B07; no propagation or routes are created here."
  value       = aws_vpn_connection.center.transit_gateway_attachment_id
}
output "customer_gateway_id" {
  description = "Selected center certificate-authenticated customer gateway reference."
  value       = aws_customer_gateway.center.id
}
output "center_prefix_list_id" {
  description = "Hub-owned prefix list reference; cross-account RAM sharing is an external contract."
  value       = aws_ec2_managed_prefix_list.center.id
}
output "selected_center" {
  description = "One center's routing destination and environment, without credentials or tunnel configuration."
  value       = merge(var.center, { environment = var.environment })
}
