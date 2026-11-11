# The workload account owns its VPC attachment to an externally shared hub.
resource "aws_ec2_transit_gateway_vpc_attachment" "environment" {
  provider                                        = aws.project
  subnet_ids                                      = var.network.transit_attachment_subnet_ids
  transit_gateway_id                              = var.hub.transit_gateway_id
  vpc_id                                          = var.network.vpc_id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  tags                                            = merge(local.tags, { Name = "${var.name_prefix}-vpc" })
}

# Cross-account acceptance belongs to the hub owner. RAM sharing is a prerequisite.
resource "aws_ec2_transit_gateway_vpc_attachment_accepter" "environment" {
  for_each                                        = var.network.account_id == var.hub.account_id ? {} : { selected = true }
  provider                                        = aws.network
  transit_gateway_attachment_id                   = aws_ec2_transit_gateway_vpc_attachment.environment.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  tags                                            = merge(local.tags, { Name = "${var.name_prefix}-accept" })
}

resource "aws_customer_gateway" "center" {
  provider        = aws.network
  certificate_arn = var.hub.customer_certificate_arn
  type            = "ipsec.1"
  tags            = merge(local.tags, { Name = "${var.name_prefix}-cgw" })
}

# One VPN contains two AWS tunnels. No PSK is accepted or output by this module.
resource "aws_vpn_connection" "center" {
  provider                 = aws.network
  customer_gateway_id      = aws_customer_gateway.center.id
  transit_gateway_id       = var.hub.transit_gateway_id
  type                     = "ipsec.1"
  static_routes_only       = true
  local_ipv4_network_cidr  = var.center.cidr_block
  remote_ipv4_network_cidr = var.network.vpc_cidr_block
  tunnel1_ike_versions     = ["ikev2"]
  tunnel2_ike_versions     = ["ikev2"]
  preshared_key_storage    = "SecretsManager"
  tags                     = merge(local.tags, { Name = "${var.name_prefix}-vpn" })
}

# Routing and firewall policy consume this reference in B07; no route is created.
resource "aws_ec2_managed_prefix_list" "center" {
  provider       = aws.network
  name           = "${var.name_prefix}-pl"
  address_family = "IPv4"
  max_entries    = 1
  entry {
    cidr        = var.center.cidr_block
    description = var.center.key
  }
  tags = merge(local.tags, { Name = "${var.name_prefix}-pl" })
}
