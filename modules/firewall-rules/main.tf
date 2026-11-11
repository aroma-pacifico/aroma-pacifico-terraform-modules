# Customer-managed prefix lists of the collection center addresses (section 5.1). Security group rules
# reference these lists, so a fourth department changes the lists and not the rules.
resource "aws_ec2_managed_prefix_list" "this" {
  for_each = local.prefix_lists

  provider = aws.project

  address_family = "IPv4"
  max_entries    = max(length(each.value.entries), 1)
  name           = "${var.name_prefix}-pl-${each.value.code}"

  dynamic "entry" {
    for_each = toset(each.value.entries)

    content {
      cidr        = entry.value
      description = "Collection center address (${each.key})"
    }
  }

  tags = merge(local.governance_tags, { Name = "${var.name_prefix}-pl-${each.value.code}" })

  lifecycle {
    precondition {
      condition     = length(local.guest_overlaps) == 0
      error_message = "A guest block overlaps an address admitted by a prefix list, so guests would reach internal segments: ${join("; ", local.guest_overlaps)}."
    }
  }
}

# CL-ADM-03: the management session host reaches device management over SSH and HTTPS. It has no
# ingress rule at all; people reach it through Session Manager.
resource "aws_security_group" "session_host" {
  provider = aws.project

  description = "Management session host: outbound to device management only"
  name        = "${var.name_prefix}-sg-ses"
  vpc_id      = var.vpc_id

  tags = merge(local.governance_tags, local.rule_tags["CL-ADM-03"], { Name = "${var.name_prefix}-sg-ses" })
}

resource "aws_vpc_security_group_egress_rule" "session_host" {
  for_each = toset(["22", "443"])

  provider = aws.project

  description       = "TCP ${each.value} to device management (CL-ADM-03)"
  from_port         = tonumber(each.value)
  ip_protocol       = "tcp"
  prefix_list_id    = aws_ec2_managed_prefix_list.this["cc_device_mgmt"].id
  security_group_id = aws_security_group.session_host.id
  to_port           = tonumber(each.value)

  tags = merge(local.governance_tags, local.rule_tags["CL-ADM-03"], { Name = "${var.name_prefix}-sg-ses" })
}

# CL-ADM-01: the Route 53 Resolver inbound endpoint answers the center firewalls on port 53.
resource "aws_security_group" "resolver" {
  provider = aws.project

  description = "Resolver inbound endpoint: DNS from the center firewalls only"
  name        = "${var.name_prefix}-sg-res"
  vpc_id      = var.vpc_id

  tags = merge(local.governance_tags, local.rule_tags["CL-ADM-01"], { Name = "${var.name_prefix}-sg-res" })
}

resource "aws_vpc_security_group_ingress_rule" "resolver" {
  for_each = toset(["tcp", "udp"])

  provider = aws.project

  description       = "DNS over ${each.value} from the center firewalls (CL-ADM-01)"
  from_port         = 53
  ip_protocol       = each.value
  prefix_list_id    = aws_ec2_managed_prefix_list.this["cc_firewalls"].id
  security_group_id = aws_security_group.resolver.id
  to_port           = 53

  tags = merge(local.governance_tags, local.rule_tags["CL-ADM-01"], { Name = "${var.name_prefix}-sg-res" })
}

# CL-DAT-02: only the application tier reaches the data store, on the ports of the store.
resource "aws_security_group" "data_store" {
  provider = aws.project

  description = "Data store: application tier only"
  name        = "${var.name_prefix}-sg-dat"
  vpc_id      = var.vpc_id

  tags = merge(local.governance_tags, local.rule_tags["CL-DAT-02"], { Name = "${var.name_prefix}-sg-dat" })
}

resource "aws_vpc_security_group_ingress_rule" "data_store" {
  for_each = local.data_store_rules

  provider = aws.project

  cidr_ipv4         = each.value.cidr_block
  description       = "TCP ${each.value.port} from the application tier (CL-DAT-02)"
  from_port         = each.value.port
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.data_store.id
  to_port           = each.value.port

  tags = merge(local.governance_tags, local.rule_tags["CL-DAT-02"], { Name = "${var.name_prefix}-sg-dat" })
}

# CL-PUB-03: a load balancer origin admits only CloudFront. Created only if the lookup chooses one.
resource "aws_security_group" "load_balancer" {
  count = var.enable_cloudfront_origin_rule ? 1 : 0

  provider = aws.project

  description = "Public lookup load balancer: CloudFront origin-facing addresses only"
  name        = "${var.name_prefix}-sg-lbo"
  vpc_id      = var.vpc_id

  tags = merge(local.governance_tags, local.rule_tags["CL-PUB-03"], { Name = "${var.name_prefix}-sg-lbo" })
}

resource "aws_vpc_security_group_ingress_rule" "load_balancer" {
  count = var.enable_cloudfront_origin_rule ? 1 : 0

  provider = aws.project

  description       = "HTTPS from the CloudFront origin-facing addresses (CL-PUB-03)"
  from_port         = 443
  ip_protocol       = "tcp"
  prefix_list_id    = data.aws_ec2_managed_prefix_list.cloudfront_origin[0].id
  security_group_id = aws_security_group.load_balancer[0].id
  to_port           = 443

  tags = merge(local.governance_tags, local.rule_tags["CL-PUB-03"], { Name = "${var.name_prefix}-sg-lbo" })
}

# Temporary rules (CL-LNK-05 style). They are added and removed through the pipeline as production
# changes; the tags let the pre-production audit (PD-125) find them and read their removal condition.
resource "aws_vpc_security_group_ingress_rule" "temporary" {
  for_each = var.temporary_rules

  provider = aws.project

  description       = "Temporary ${each.value.rule_id}: removed when ${each.value.removal_condition}"
  from_port         = each.value.from_port
  ip_protocol       = each.value.protocol
  prefix_list_id    = aws_ec2_managed_prefix_list.this[each.value.source_prefix_list].id
  security_group_id = each.value.security_group_id
  to_port           = each.value.to_port

  tags = merge(local.governance_tags, local.rule_tags[each.value.rule_id], {
    Name             = "${var.name_prefix}-tmp-${each.key}"
    RemovalCondition = each.value.removal_condition
  })
}

# Interface endpoint policies (CL-APP-02, CL-DRN-02). The endpoints belong to the network module.
resource "aws_vpc_endpoint_policy" "this" {
  for_each = local.endpoint_policies

  provider = aws.project

  vpc_endpoint_id = each.value.endpoint_id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = each.value.statements
  })
}
