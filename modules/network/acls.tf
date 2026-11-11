# Network ACLs, one per tier. They are the stateless second layer of the cloud firewall policy; every
# tier ends with an explicit deny in both directions (CL-DEF-01).
resource "aws_network_acl" "this" {
  for_each = local.tiers

  provider = aws.project

  subnet_ids = [for az in local.az_slots : aws_subnet.this["${each.key}-${az}"].id]
  vpc_id     = aws_vpc.this.id

  tags = merge(local.governance_tags, { Name = "${var.name_prefix}-nacl-${each.value.code}" })
}

resource "aws_network_acl_rule" "this" {
  for_each = local.acl_rules

  provider = aws.project

  cidr_block     = each.value.cidr_block
  egress         = each.value.egress
  from_port      = each.value.from_port
  network_acl_id = aws_network_acl.this[each.value.tier].id
  protocol       = each.value.protocol
  rule_action    = each.value.action
  rule_number    = each.value.rule_number
  to_port        = each.value.to_port
}
