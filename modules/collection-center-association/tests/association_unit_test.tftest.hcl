mock_provider "aws" {
  alias           = "project"
  override_during = plan
  mock_resource "aws_ec2_transit_gateway_vpc_attachment" { defaults = { id = "tgw-attach-00000000000000001" } }
}
mock_provider "aws" {
  alias           = "network"
  override_during = plan
  mock_resource "aws_customer_gateway" { defaults = { id = "cgw-00000000000000001" } }
  mock_resource "aws_vpn_connection" { defaults = { id = "vpn-00000000000000001", transit_gateway_attachment_id = "tgw-attach-00000000000000002", customer_gateway_configuration = "", tunnel1_preshared_key = "", tunnel2_preshared_key = "" } }
  mock_resource "aws_ec2_managed_prefix_list" { defaults = { id = "pl-00000000000000001" } }
}
variables {
  client      = "fx"
  project     = "cf"
  environment = "pdn"
  name_prefix = "fx-cf-pdn-cc"
  center      = { key = "fixture", cidr_block = "10.41.0.0/16" }
  network     = { environment = "pdn", account_id = format("%012d", 0), vpc_id = "vpc-00000000000000000", vpc_cidr_block = "10.82.0.0/16", transit_attachment_subnet_ids = ["subnet-00000000000000001", "subnet-00000000000000002", "subnet-00000000000000003"] }
  hub         = { account_id = format("%012d", 1), region = "us-east-1", transit_gateway_id = "tgw-00000000000000000", customer_certificate_arn = "arn:aws:acm:us-east-1:${format("%012d", 1)}:certificate/00000000-0000-0000-0000-000000000000" }
}
run "cross_account_graph" {
  command = plan
  assert {
    condition     = length(aws_ec2_transit_gateway_vpc_attachment_accepter.environment) == 1 && aws_ec2_transit_gateway_vpc_attachment.environment.id == "tgw-attach-00000000000000001" && output.vpn_connection_id == "vpn-00000000000000001" && output.center_prefix_list_id == "pl-00000000000000001" && output.customer_gateway_id == "cgw-00000000000000001" && output.vpn_attachment_id == "tgw-attach-00000000000000002"
    error_message = "One cross-account attachment, accepter, customer gateway, VPN and prefix list must use the injected owner providers."
  }
  assert {
    condition     = !aws_ec2_transit_gateway_vpc_attachment.environment.transit_gateway_default_route_table_association && !aws_ec2_transit_gateway_vpc_attachment.environment.transit_gateway_default_route_table_propagation && aws_vpn_connection.center.static_routes_only && aws_vpn_connection.center.tunnel1_ike_versions == toset(["ikev2"]) && aws_vpn_connection.center.tunnel2_ike_versions == toset(["ikev2"]) && aws_vpn_connection.center.preshared_key_storage == "SecretsManager"
    error_message = "Default VPC propagation must be disabled; both VPN tunnels require IKEv2, static routes and external secret storage."
  }
  assert {
    condition     = one(aws_ec2_managed_prefix_list.center.entry).cidr == var.center.cidr_block && aws_vpn_connection.center.local_ipv4_network_cidr == var.center.cidr_block && aws_customer_gateway.center.certificate_arn == var.hub.customer_certificate_arn && output.selected_center.environment == "pdn"
    error_message = "One approved center block and public certificate reference must propagate to the connection graph."
  }
}
run "same_account_graph" {
  command = plan
  variables {
    hub = { account_id = format("%012d", 0), region = "us-east-1", transit_gateway_id = "tgw-00000000000000000", customer_certificate_arn = "arn:aws:acm:us-east-1:${format("%012d", 0)}:certificate/00000000-0000-0000-0000-000000000000" }
  }
  assert {
    condition     = length(aws_ec2_transit_gateway_vpc_attachment_accepter.environment) == 0
    error_message = "Same-account attachments must not acquire a redundant accepter."
  }
}
run "dev_forbidden" {
  command = plan
  variables {
    environment = "dev"
    name_prefix = "fx-cf-dev-cc"
    network     = { environment = "dev", account_id = format("%012d", 0), vpc_id = "vpc-00000000000000000", vpc_cidr_block = "10.82.0.0/16", transit_attachment_subnet_ids = ["subnet-00000000000000001"] }
  }
  expect_failures = [var.environment]
}
run "qa_permanent_forbidden" {
  command = plan
  variables {
    environment = "qa"
    name_prefix = "fx-cf-qa-cc"
    network     = { environment = "qa", account_id = format("%012d", 0), vpc_id = "vpc-00000000000000000", vpc_cidr_block = "10.82.0.0/16", transit_attachment_subnet_ids = ["subnet-00000000000000001"] }
  }
  expect_failures = [var.environment]
}
run "bad_center" {
  command = plan
  variables {
    center = { key = "fixture", cidr_block = "10.41.1.0/16" }
  }
  expect_failures = [var.center]
}
run "missing_subnets" {
  command = plan
  variables {
    network = { environment = "pdn", account_id = format("%012d", 0), vpc_id = "vpc-00000000000000000", vpc_cidr_block = "10.82.0.0/16", transit_attachment_subnet_ids = [] }
  }
  expect_failures = [var.network]
}
run "overlap" {
  command = plan
  variables {
    network = { environment = "pdn", account_id = format("%012d", 0), vpc_id = "vpc-00000000000000000", vpc_cidr_block = "10.41.0.0/16", transit_attachment_subnet_ids = ["subnet-00000000000000001"] }
  }
  expect_failures = [var.network]
}
run "missing_certificate" {
  command = plan
  variables {
    hub = { account_id = format("%012d", 1), region = "us-east-1", transit_gateway_id = "tgw-00000000000000000", customer_certificate_arn = "" }
  }
  expect_failures = [var.hub]
}
