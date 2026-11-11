# VPC and subnets. Routing, network ACLs and endpoints are added by later parts of B04a.
resource "aws_vpc" "this" {
  provider = aws.project

  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.governance_tags, { Name = "${var.name_prefix}-vpc-main" })

  lifecycle {
    precondition {
      condition = alltrue([
        for center in keys(var.collection_center_cidr_blocks) :
        local.cidr_ranges["vpc"].last < local.cidr_ranges["center-${center}"].first || local.cidr_ranges["center-${center}"].last < local.cidr_ranges["vpc"].first
      ])
      error_message = "VPC CIDR block must not overlap any collection center CIDR block."
    }

    precondition {
      condition = alltrue([
        for center in keys(var.collection_center_cidr_blocks) :
        local.cidr_ranges["summary"].first <= local.cidr_ranges["center-${center}"].first && local.cidr_ranges["center-${center}"].last <= local.cidr_ranges["summary"].last
      ]) && (local.cidr_ranges["summary"].last < local.cidr_ranges["vpc"].first || local.cidr_ranges["vpc"].last < local.cidr_ranges["summary"].first)
      error_message = "Collection center summary must contain every center block and must not overlap the VPC CIDR block."
    }

    precondition {
      condition     = alltrue([for key in keys(local.subnets) : local.cidr_ranges["subnet-${key}"].first >= local.cidr_ranges["vpc"].first && local.cidr_ranges["subnet-${key}"].last <= local.cidr_ranges["vpc"].last])
      error_message = "Every subnet CIDR block must lie inside the VPC CIDR block."
    }
  }
}

resource "aws_subnet" "this" {
  for_each = local.subnets

  provider = aws.project

  availability_zone_id    = local.az_ids[each.value.az]
  cidr_block              = each.value.cidr_block
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.this.id

  tags = merge(local.governance_tags, { Name = each.value.name })
}
