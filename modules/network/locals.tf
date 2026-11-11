locals {
  # Tier keys and physical name codes come from the addressing plan (section 4 and 4.3).
  tiers = {
    public_query         = { code = "pubq" }
    telemetry_ingress    = { code = "tlmi" }
    drone_object_ingress = { code = "droi" }
    application          = { code = "app" }
    data                 = { code = "data" }
    object_storage       = { code = "objs" }
    administration       = { code = "adm" }
    transit              = { code = "tgw" }
  }

  # Three active Availability Zone slots; az4 is reserved by the plan and never created.
  az_slots = ["az1", "az2", "az3"]
  az_ids   = zipmap(local.az_slots, slice(sort(data.aws_availability_zones.available.zone_ids), 0, length(local.az_slots)))

  # PC-IAC-003 caps a physical name at 28 characters. The longest suffix this module appends is
  # 12 characters ("-vpce-" plus a 6 character endpoint key), which leaves 16 for the prefix.
  max_name_prefix_length = 16

  governance_tags = merge({
    Client      = var.client
    Project     = var.project
    Environment = var.environment
  }, var.additional_tags)

  subnets = merge([
    for tier, azs in var.subnets : {
      for az, cidr_block in azs : "${tier}-${az}" => {
        az         = az
        cidr_block = cidr_block
        name       = "${var.name_prefix}-snet-${local.tiers[tier].code}${trimprefix(az, "az")}"
      }
    }
  ]...)
  # Terraform has no CIDR overlap function, so every block is reduced to its first and last address
  # as integers. Two blocks overlap exactly when their integer ranges intersect.
  cidr_blocks = merge(
    { vpc = var.vpc_cidr_block },
    { for center, cidr_block in var.collection_center_cidr_blocks : "center-${center}" => cidr_block },
    { for key, subnet in local.subnets : "subnet-${key}" => subnet.cidr_block },
  )
  cidr_ranges = {
    for key, cidr_block in local.cidr_blocks : key => {
      first = sum([for index, octet in split(".", cidrhost(cidr_block, 0)) : tonumber(octet) * pow(256, 3 - index)])
      last  = sum([for index, octet in split(".", cidrhost(cidr_block, 0)) : tonumber(octet) * pow(256, 3 - index)]) + pow(2, 32 - tonumber(split("/", cidr_block)[1])) - 1
    }
  }
}
