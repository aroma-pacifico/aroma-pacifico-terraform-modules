mock_provider "aws" {
  alias           = "project"
  override_during = plan

  mock_data "aws_availability_zones" {
    defaults = { zone_ids = ["use1-az4", "use1-az1", "use1-az2", "use1-az6"] }
  }
}

variables {
  transit_gateway_id                   = "tgw-0123456789abcdef0"
  collection_center_summary_cidr_block = "10.40.0.0/13"
  client                               = "fx"
  project                              = "cf"
  environment                          = "pdn"
  name_prefix                          = "fx-cf-pdn"
  vpc_cidr_block                       = "10.82.0.0/16"
  collection_center_cidr_blocks = {
    cauca  = "10.41.0.0/16"
    huila  = "10.42.0.0/16"
    tolima = "10.43.0.0/16"
  }
  subnets = {
    public_query         = { az1 = "10.82.0.0/22", az2 = "10.82.4.0/22", az3 = "10.82.8.0/22" }
    telemetry_ingress    = { az1 = "10.82.16.0/22", az2 = "10.82.20.0/22", az3 = "10.82.24.0/22" }
    drone_object_ingress = { az1 = "10.82.32.0/22", az2 = "10.82.36.0/22", az3 = "10.82.40.0/22" }
    application          = { az1 = "10.82.48.0/22", az2 = "10.82.52.0/22", az3 = "10.82.56.0/22" }
    data                 = { az1 = "10.82.64.0/22", az2 = "10.82.68.0/22", az3 = "10.82.72.0/22" }
    object_storage       = { az1 = "10.82.80.0/22", az2 = "10.82.84.0/22", az3 = "10.82.88.0/22" }
    administration       = { az1 = "10.82.96.0/22", az2 = "10.82.100.0/22", az3 = "10.82.104.0/22" }
    transit              = { az1 = "10.82.240.0/28", az2 = "10.82.240.16/28", az3 = "10.82.240.32/28" }
  }
}

run "pdn_layout" {
  command = plan

  assert {
    condition     = length(aws_subnet.this) == 24 && length(output.subnet_ids) == 8 && alltrue([for azs in values(output.subnet_ids) : length(azs) == 3])
    error_message = "The plan must create eight tiers with three subnets each and no az4."
  }

  assert {
    condition     = output.availability_zone_ids["az1"] == "use1-az1" && output.availability_zone_ids["az2"] == "use1-az2" && output.availability_zone_ids["az3"] == "use1-az4" && length(output.availability_zone_ids) == 3
    error_message = "Availability Zone slots must map to the first three zone IDs in sorted order."
  }

  assert {
    condition     = aws_vpc.this.tags["Name"] == "fx-cf-pdn-vpc-main" && aws_subnet.this["telemetry_ingress-az1"].tags["Name"] == "fx-cf-pdn-snet-tlmi1" && aws_subnet.this["transit-az3"].tags["Name"] == "fx-cf-pdn-snet-tgw3"
    error_message = "Physical names must follow PC-IAC-003 with the tier codes of the addressing plan."
  }

  assert {
    condition     = alltrue([for subnet in values(aws_subnet.this) : !subnet.map_public_ip_on_launch && length(subnet.tags["Name"]) <= 28])
    error_message = "Subnets must never assign public addresses and must keep names within 28 characters."
  }

  # Every block is /16 or longer, so it overlaps 10.41/16, 10.42/16 or 10.43/16 only if its first two octets match.
  assert {
    condition = alltrue([
      for cidr_block in concat([aws_vpc.this.cidr_block], [for subnet in values(aws_subnet.this) : subnet.cidr_block]) :
      !contains(["10.41", "10.42", "10.43"], join(".", slice(split(".", cidrhost(cidr_block, 0)), 0, 2)))
    ])
    error_message = "The VPC and its subnets must not overlap 10.41.0.0/16, 10.42.0.0/16 or 10.43.0.0/16."
  }
}

run "az4_is_rejected" {
  command = plan

  variables {
    subnets = merge(var.subnets, { data = { az1 = "10.82.64.0/22", az2 = "10.82.68.0/22", az3 = "10.82.72.0/22", az4 = "10.82.76.0/22" } })
  }

  expect_failures = [var.subnets]
}

run "unknown_tier_is_rejected" {
  command = plan

  variables {
    subnets = { for tier, azs in var.subnets : (tier == "transit" ? "extra" : tier) => azs }
  }

  expect_failures = [var.subnets]
}

run "subnet_outside_the_vpc_is_rejected" {
  command = plan

  variables {
    subnets = merge(var.subnets, { data = { az1 = "10.99.64.0/22", az2 = "10.82.68.0/22", az3 = "10.82.72.0/22" } })
  }

  expect_failures = [aws_vpc.this]
}

run "vpc_overlapping_a_center_is_rejected" {
  command = plan

  variables {
    vpc_cidr_block = "10.42.0.0/16"
  }

  expect_failures = [aws_vpc.this]
}

run "long_name_prefix_is_rejected" {
  command = plan

  variables {
    name_prefix = "acme-pilot-pdn-extra"
  }

  expect_failures = [var.name_prefix]
}

run "routing_follows_the_firewall_policy" {
  command = plan

  # The mock gives every instance the same generated ID, so three tiers get distinct IDs to prove the wiring.
  override_resource {
    target          = aws_route_table.this["public_query"]
    values          = { id = "rtb-pubq" }
    override_during = plan
  }

  override_resource {
    target          = aws_route_table.this["data"]
    values          = { id = "rtb-data" }
    override_during = plan
  }

  override_resource {
    target          = aws_route_table.this["transit"]
    values          = { id = "rtb-tgw" }
    override_during = plan
  }

  assert {
    condition     = length(aws_route_table.this) == 8 && length(aws_route_table_association.this) == 24 && aws_internet_gateway.this.tags["Name"] == "fx-cf-pdn-igw-main"
    error_message = "The plan must create one route table per tier and associate all 24 subnets."
  }

  assert {
    condition     = aws_route_table_association.this["public_query-az1"].route_table_id == "rtb-pubq" && aws_route_table_association.this["data-az3"].route_table_id == "rtb-data" && aws_route_table_association.this["transit-az2"].route_table_id == "rtb-tgw"
    error_message = "Every subnet must use the route table of its own tier."
  }

  assert {
    condition     = aws_route.internet.destination_cidr_block == "0.0.0.0/0"
    error_message = "The default route must target 0.0.0.0/0."
  }

  assert {
    condition     = aws_route.internet.route_table_id == "rtb-pubq"
    error_message = "Only public_query may carry the default route to the internet gateway."
  }

  assert {
    condition     = toset(keys(aws_route.centers)) == toset(["application", "drone_object_ingress", "object_storage", "administration"]) && alltrue([for route in values(aws_route.centers) : route.destination_cidr_block == "10.40.0.0/13" && route.transit_gateway_id == var.transit_gateway_id])
    error_message = "Only application, drone_object_ingress, object_storage and administration may route 10.40.0.0/13 to the transit gateway (CL-LNK-07)."
  }

  assert {
    condition     = length(output.transit_attachment_subnet_ids) == 3 && length(output.route_table_ids) == 8
    error_message = "The module must expose the transit subnets and the route tables."
  }
}

run "no_transit_gateway_means_no_center_routes" {
  command = plan

  variables {
    transit_gateway_id = null
  }

  assert {
    condition     = length(aws_route.centers) == 0
    error_message = "Without a transit gateway the module must create no route to the collection centers."
  }
}

run "summary_that_misses_a_center_is_rejected" {
  command = plan

  variables {
    collection_center_summary_cidr_block = "10.48.0.0/13"
  }

  expect_failures = [aws_vpc.this]
}

run "summary_overlapping_the_vpc_is_rejected" {
  command = plan

  variables {
    collection_center_summary_cidr_block = "10.80.0.0/13"
  }

  expect_failures = [aws_vpc.this]
}

run "bad_transit_gateway_id_is_rejected" {
  command = plan

  variables {
    transit_gateway_id = "not-a-gateway"
  }

  expect_failures = [var.transit_gateway_id]
}
