mock_provider "aws" {
  alias           = "principal"
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
  center  = { key = "fixture", cidr_block = "10.41.0.0/16" }
  network = { environment = "pdn", account_id = format("%012d", 0), vpc_id = "vpc-00000000000000000", vpc_cidr_block = "10.82.0.0/16", transit_attachment_subnet_ids = ["subnet-00000000000000001", "subnet-00000000000000002", "subnet-00000000000000003"] }
  hub     = { account_id = format("%012d", 1), region = "us-east-1", transit_gateway_id = "tgw-00000000000000000", customer_certificate_arn = "arn:aws:acm:us-east-1:${format("%012d", 1)}:certificate/00000000-0000-0000-0000-000000000000" }
}
run "single_association" {
  command = plan
  assert {
    condition     = output.selected_center.key == "fixture" && output.routing_references.vpc_attachment_id == "tgw-attach-00000000000000001" && output.routing_references.vpn_attachment_id == "tgw-attach-00000000000000002"
    error_message = "The root must inject both provider owners and expose the B07 contract."
  }
}
