# Routing. The internet gateway serves public_query only. Private tiers have no default route and no
# NAT gateway (CL-EGR-01), so they cannot reach the internet.
resource "aws_internet_gateway" "this" {
  provider = aws.project

  vpc_id = aws_vpc.this.id

  tags = merge(local.governance_tags, { Name = "${var.name_prefix}-igw-main" })
}

resource "aws_route_table" "this" {
  for_each = local.tiers

  provider = aws.project

  vpc_id = aws_vpc.this.id

  tags = merge(local.governance_tags, { Name = "${var.name_prefix}-rtb-${each.value.code}" })
}

resource "aws_route_table_association" "this" {
  for_each = local.subnets

  provider = aws.project

  route_table_id = aws_route_table.this[each.value.tier].id
  subnet_id      = aws_subnet.this[each.key].id
}

resource "aws_route" "internet" {
  provider = aws.project

  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
  route_table_id         = aws_route_table.this["public_query"].id
}

# One summary route to every present and future collection center (CL-LNK-07). The transit gateway
# and its VPC attachment belong to the network account, not to this module.
resource "aws_route" "centers" {
  for_each = local.center_routed_tiers

  provider = aws.project

  destination_cidr_block = var.collection_center_summary_cidr_block
  route_table_id         = aws_route_table.this[each.key].id
  transit_gateway_id     = var.transit_gateway_id
}
