mock_provider "aws" {
  alias           = "principal"
  override_during = plan

  mock_data "aws_region" {
    defaults = { region = "us-east-1" }
  }

  mock_data "aws_availability_zones" {
    defaults = { zone_ids = ["use1-az1", "use1-az2", "use1-az4", "use1-az6"] }
  }
}
mock_provider "aws" {
  alias           = "network"
  override_during = plan
  mock_resource "aws_customer_gateway" { defaults = { id = "cgw-00000000000000001" } }
  mock_resource "aws_vpn_connection" { defaults = { id = "vpn-00000000000000001", transit_gateway_attachment_id = "tgw-attach-00000000000000002", customer_gateway_configuration = "", tunnel1_preshared_key = "", tunnel2_preshared_key = "" } }
  mock_resource "aws_ec2_managed_prefix_list" { defaults = { id = "pl-00000000000000001" } }
}
override_resource {
  target          = module.network.aws_subnet.this["transit-az1"]
  values          = { id = "subnet-00000000000000001" }
  override_during = plan
}
override_resource {
  target          = module.network.aws_subnet.this["transit-az2"]
  values          = { id = "subnet-00000000000000002" }
  override_during = plan
}
override_resource {
  target          = module.network.aws_subnet.this["transit-az3"]
  values          = { id = "subnet-00000000000000003" }
  override_during = plan
}
override_resource {
  target          = module.network.aws_vpc.this
  values          = { id = "vpc-00000000000000000" }
  override_during = plan
}
run "reviewed_b04_outputs" {
  command = plan
  assert {
    condition     = module.association.selected_center.cidr_block == "10.41.0.0/16" && module.association.vpn_connection_id == "vpn-00000000000000001" && length(module.network.transit_attachment_subnet_ids) == 3
    error_message = "The real reviewed B04 output expressions must feed one B05 graph."
  }
}
