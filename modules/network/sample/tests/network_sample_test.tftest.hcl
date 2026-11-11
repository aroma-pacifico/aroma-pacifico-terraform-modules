mock_provider "aws" {
  alias           = "principal"
  override_during = plan

  mock_data "aws_availability_zones" {
    defaults = { zone_ids = ["use1-az1", "use1-az2", "use1-az4", "use1-az6"] }
  }
}

run "sample_plans_without_overlapping_the_centers" {
  command = plan

  assert {
    condition     = length(module.network.subnet_ids) == 8 && alltrue([for azs in values(module.network.subnet_ids) : length(azs) == 3])
    error_message = "The sample must plan eight tiers with three subnets each."
  }

  # Every block is /16 or longer, so it overlaps 10.41/16, 10.42/16 or 10.43/16 only if its first two octets match.
  assert {
    condition = alltrue([
      for cidr_block in concat([var.vpc_cidr_block], flatten([for azs in values(var.subnets) : values(azs)])) :
      !contains(["10.41", "10.42", "10.43"], join(".", slice(split(".", cidrhost(cidr_block, 0)), 0, 2)))
    ])
    error_message = "The sample CIDR blocks must not overlap 10.41.0.0/16, 10.42.0.0/16 or 10.43.0.0/16."
  }
}
