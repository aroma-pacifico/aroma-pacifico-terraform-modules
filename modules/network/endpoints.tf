# VPC endpoints keep AWS service traffic off the internet (PC-IAC-020, CL-EGR-01).

# Gateway endpoints for S3 and DynamoDB attach to the route tables of the private tiers. The policy
# admits only resources of the organization (CL-DAT-03).
resource "aws_vpc_endpoint" "gateway" {
  for_each = local.gateway_services

  provider = aws.project

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "${each.value}:*"
      Resource  = "*"
      Condition = { StringEquals = { "aws:ResourceOrgID" = var.organization_id } }
    }]
  })
  route_table_ids   = [for tier in local.private_tiers : aws_route_table.this[tier].id]
  service_name      = "com.amazonaws.${data.aws_region.current.region}.${each.value}"
  vpc_endpoint_type = "Gateway"
  vpc_id            = aws_vpc.this.id

  tags = merge(local.governance_tags, { Name = "${var.name_prefix}-vpce-${each.key}" })
}

# One security group per tier that hosts interface endpoints. HTTPS only, from the VPC and the
# collection centers; no rule opens 0.0.0.0/0.
resource "aws_security_group" "endpoints" {
  for_each = local.endpoint_tiers

  provider = aws.project

  description = "HTTPS to the interface endpoints of the ${each.key} tier"
  name        = "${var.name_prefix}-sg-${local.tiers[each.key].code}"
  vpc_id      = aws_vpc.this.id

  tags = merge(local.governance_tags, { Name = "${var.name_prefix}-sg-${local.tiers[each.key].code}" })
}

resource "aws_vpc_security_group_ingress_rule" "endpoints" {
  for_each = local.endpoint_ingress_rules

  provider = aws.project

  cidr_ipv4         = each.value.cidr_block
  description       = "HTTPS from ${each.value.source}"
  from_port         = 443
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.endpoints[each.value.tier].id
  to_port           = 443

  tags = merge(local.governance_tags, { Name = "${var.name_prefix}-sg-${local.tiers[each.value.tier].code}" })
}

resource "aws_vpc_endpoint" "interface" {
  for_each = var.interface_endpoints

  provider = aws.project

  private_dns_enabled = true
  security_group_ids  = [aws_security_group.endpoints[each.value.tier].id]
  service_name        = "com.amazonaws.${data.aws_region.current.region}.${each.value.service}"
  subnet_ids          = [for az in local.az_slots : aws_subnet.this["${each.value.tier}-${az}"].id]
  vpc_endpoint_type   = "Interface"
  vpc_id              = aws_vpc.this.id

  tags = merge(local.governance_tags, { Name = "${var.name_prefix}-vpce-${each.key}" })
}

# Rejected traffic is logged to the destination supplied by the security stack (CL-DEF-02).
resource "aws_flow_log" "rejected" {
  count = var.flow_logs == null ? 0 : 1

  provider = aws.project

  iam_role_arn         = var.flow_logs.iam_role_arn
  log_destination      = var.flow_logs.destination_arn
  log_destination_type = "cloud-watch-logs"
  traffic_type         = "REJECT"
  vpc_id               = aws_vpc.this.id

  tags = merge(local.governance_tags, { Name = "${var.name_prefix}-flow-rej" })
}
