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
        tier       = tier
        cidr_block = cidr_block
        name       = "${var.name_prefix}-snet-${local.tiers[tier].code}${trimprefix(az, "az")}"
      }
    }
  ]...)
  # CL-LNK-07: only these tiers carry the route to the collection centers. drone_object_ingress keeps it
  # as a documented reservation although it holds no endpoint (PD-140, ASM-140). No transit gateway, no route.
  center_routed_tiers = var.transit_gateway_id == null ? toset([]) : toset(["application", "drone_object_ingress", "object_storage", "administration"])

  # Network ACL rules of the firewall policy (rows CL-*). One spec per rule family; a spec with several
  # CIDR blocks expands to one rule per block. Rule numbers follow the order of the list.
  anywhere                = ["0.0.0.0/0"]
  centers_and_vpc         = [var.collection_center_summary_cidr_block, var.vpc_cidr_block]
  stations_and_vpc        = concat(values(var.collection_center_ground_station_cidr_blocks), [var.vpc_cidr_block])
  application_cidr_blocks = values(var.subnets["application"])
  firewall_cidr_blocks    = values(var.collection_center_firewall_cidr_blocks)

  acl_specs = {
    # CL-PUB-04: the only internet-facing tier.
    public_query = {
      ingress = [{ protocol = "tcp", action = "allow", cidrs = local.anywhere, from_port = 443, to_port = 443 }]
      egress  = [{ protocol = "tcp", action = "allow", cidrs = local.anywhere, from_port = 1024, to_port = 65535 }]
    }
    # CL-TEL-04: no private telemetry path in the pilot, so only the final deny applies.
    telemetry_ingress = { ingress = [], egress = [] }
    # CL-DRN-04: sources are the ground stations and the VPC. drone_object_ingress holds no endpoint (PD-140).
    drone_object_ingress = {
      ingress = [
        { protocol = "tcp", action = "allow", cidrs = local.stations_and_vpc, from_port = 443, to_port = 443 },
        { protocol = "tcp", action = "allow", cidrs = local.anywhere, from_port = 1024, to_port = 65535 },
      ]
      egress = [
        { protocol = "tcp", action = "allow", cidrs = local.stations_and_vpc, from_port = 1024, to_port = 65535 },
        { protocol = "tcp", action = "allow", cidrs = local.anywhere, from_port = 443, to_port = 443 },
      ]
    }
    object_storage = {
      ingress = [
        { protocol = "tcp", action = "allow", cidrs = local.stations_and_vpc, from_port = 443, to_port = 443 },
        { protocol = "tcp", action = "allow", cidrs = local.anywhere, from_port = 1024, to_port = 65535 },
      ]
      egress = [
        { protocol = "tcp", action = "allow", cidrs = local.stations_and_vpc, from_port = 1024, to_port = 65535 },
        { protocol = "tcp", action = "allow", cidrs = local.anywhere, from_port = 443, to_port = 443 },
      ]
    }
    # CL-APP-03: outbound 443 to anywhere stays open because gateway endpoint destinations are AWS public
    # ranges that an ACL cannot name; security groups narrow it (pc-iac-020 exception, see the README).
    application = {
      ingress = [
        { protocol = "tcp", action = "allow", cidrs = local.centers_and_vpc, from_port = 443, to_port = 443 },
        { protocol = "tcp", action = "allow", cidrs = local.anywhere, from_port = 1024, to_port = 65535 },
      ]
      egress = [
        { protocol = "tcp", action = "allow", cidrs = local.centers_and_vpc, from_port = 1024, to_port = 65535 },
        { protocol = "tcp", action = "allow", cidrs = local.anywhere, from_port = 443, to_port = 443 },
      ]
    }
    # CL-DAT-01 and CL-DAT-02: deny every center first, then allow the application tier on the store ports.
    # The egress rule is the stateless return path. An empty port list leaves only the denies.
    data = {
      ingress = concat(
        [{ protocol = "-1", action = "deny", cidrs = [var.collection_center_summary_cidr_block], from_port = null, to_port = null }],
        [for port in var.data_store_ports : { protocol = "tcp", action = "allow", cidrs = local.application_cidr_blocks, from_port = port, to_port = port }],
      )
      egress = [{ protocol = "tcp", action = "allow", cidrs = local.application_cidr_blocks, from_port = 1024, to_port = 65535 }]
    }
    # CL-ADM-04
    administration = {
      ingress = [
        { protocol = "udp", action = "allow", cidrs = local.firewall_cidr_blocks, from_port = 53, to_port = 53 },
        { protocol = "tcp", action = "allow", cidrs = local.firewall_cidr_blocks, from_port = 53, to_port = 53 },
        { protocol = "tcp", action = "allow", cidrs = local.firewall_cidr_blocks, from_port = 443, to_port = 443 },
        { protocol = "tcp", action = "allow", cidrs = [var.collection_center_summary_cidr_block], from_port = 1024, to_port = 65535 },
        { protocol = "tcp", action = "allow", cidrs = [var.vpc_cidr_block], from_port = 443, to_port = 443 },
      ]
      egress = [
        { protocol = "udp", action = "allow", cidrs = local.firewall_cidr_blocks, from_port = 1024, to_port = 65535 },
        { protocol = "tcp", action = "allow", cidrs = local.firewall_cidr_blocks, from_port = 1024, to_port = 65535 },
        { protocol = "tcp", action = "allow", cidrs = [var.collection_center_summary_cidr_block], from_port = 22, to_port = 22 },
        { protocol = "tcp", action = "allow", cidrs = [var.collection_center_summary_cidr_block], from_port = 443, to_port = 443 },
        { protocol = "tcp", action = "allow", cidrs = [var.vpc_cidr_block], from_port = 1024, to_port = 65535 },
      ]
    }
    # CL-LNK-08: attachment subnets pass only center and VPC traffic.
    transit = {
      ingress = [{ protocol = "-1", action = "allow", cidrs = local.centers_and_vpc, from_port = null, to_port = null }]
      egress  = [{ protocol = "-1", action = "allow", cidrs = local.centers_and_vpc, from_port = null, to_port = null }]
    }
  }

  acl_rules = merge(
    merge([
      for tier, directions in local.acl_specs : merge([
        for direction, specs in directions : {
          for index, rule in flatten([for spec in specs : [for cidr_block in spec.cidrs : merge(spec, { cidr_block = cidr_block })]]) :
          "${tier}-${direction}-${index}" => merge(rule, { tier = tier, egress = direction == "egress", rule_number = 100 + 10 * index })
        }
      ]...)
    ]...),
    {
      for pair in setproduct(keys(local.tiers), ["ingress", "egress"]) : "${pair[0]}-${pair[1]}-final" => {
        tier       = pair[0], egress = pair[1] == "egress", rule_number = 32766, protocol = "-1", action = "deny"
        cidr_block = "0.0.0.0/0", from_port = null, to_port = null
      }
    },
  )

  # Gateway endpoints: key is the name suffix, value is the service (at most 6 characters in the key).
  gateway_services = { s3gw = "s3", ddbgw = "dynamodb" }
  # CL-DAT-03: every tier except the public one reaches AWS services through the endpoints.
  private_tiers = [for tier in keys(local.tiers) : tier if tier != "public_query"]

  endpoint_tiers = toset([for endpoint in values(var.interface_endpoints) : endpoint.tier])
  endpoint_ingress_rules = {
    for pair in setproduct(local.endpoint_tiers, ["vpc", "centers"]) : "${pair[0]}-${pair[1]}" => {
      tier       = pair[0]
      source     = pair[1] == "vpc" ? "the VPC" : "the collection centers"
      cidr_block = pair[1] == "vpc" ? var.vpc_cidr_block : var.collection_center_summary_cidr_block
    }
  }

  # Terraform has no CIDR overlap function, so every block is reduced to its first and last address
  # as integers. Two blocks overlap exactly when their integer ranges intersect.
  cidr_blocks = merge(
    { vpc = var.vpc_cidr_block, summary = var.collection_center_summary_cidr_block },
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
