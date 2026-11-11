mock_provider "aws" {
  alias           = "project"
  override_during = plan

  mock_data "aws_availability_zones" {
    defaults = { zone_ids = ["use1-az4", "use1-az1", "use1-az2", "use1-az6"] }
  }
}

variables {
  client         = "fx"
  project        = "cf"
  environment    = "pdn"
  name_prefix    = "fx-cf-pdn"
  vpc_cidr_block = "10.82.0.0/16"
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
