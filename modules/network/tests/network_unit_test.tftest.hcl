mock_provider "aws" {
  alias           = "project"
  override_during = plan

  mock_data "aws_region" {
    defaults = { region = "us-east-1" }
  }

  mock_resource "aws_route_table" {
    defaults = { id = "rtb-mock" }
  }

  mock_resource "aws_security_group" {
    defaults = { id = "sg-mock" }
  }

  mock_resource "aws_subnet" {
    defaults = { id = "subnet-mock" }
  }

  mock_data "aws_availability_zones" {
    defaults = { zone_ids = ["use1-az4", "use1-az1", "use1-az2", "use1-az6"] }
  }
}

variables {
  organization_id = "o-a1b2c3d4e5"
  interface_endpoints = {
    cogn  = { service = "cognito-idp", tier = "application" }
    exapi = { service = "execute-api", tier = "application" }
    s3    = { service = "s3", tier = "object_storage" }
    logs  = { service = "logs", tier = "administration" }
    mon   = { service = "monitoring", tier = "administration" }
    rola  = { service = "rolesanywhere", tier = "administration" }
  }
  collection_center_firewall_cidr_blocks       = { cauca = "10.41.20.1/32", huila = "10.42.20.1/32", tolima = "10.43.20.1/32" }
  collection_center_ground_station_cidr_blocks = { cauca = "10.41.2.10/32", huila = "10.42.2.10/32", tolima = "10.43.2.10/32" }
  data_store_ports                             = [5432]
  transit_gateway_id                           = "tgw-0123456789abcdef0"
  collection_center_summary_cidr_block         = "10.40.0.0/13"
  client                                       = "fx"
  project                                      = "cf"
  environment                                  = "pdn"
  name_prefix                                  = "fx-cf-pdn"
  vpc_cidr_block                               = "10.82.0.0/16"
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

run "acls_follow_the_firewall_policy" {
  command = plan

  assert {
    condition     = length(aws_network_acl.this) == 8 && length(output.network_acl_ids) == 8
    error_message = "The plan must create one network ACL per tier."
  }

  assert {
    condition = alltrue([
      for tier in ["public_query", "telemetry_ingress", "drone_object_ingress", "application", "data", "object_storage", "administration", "transit"] :
      aws_network_acl_rule.this["${tier}-ingress-final"].rule_action == "deny" && aws_network_acl_rule.this["${tier}-egress-final"].rule_action == "deny" && aws_network_acl_rule.this["${tier}-egress-final"].rule_number == 32766
    ])
    error_message = "Every tier must end with an explicit deny in both directions (CL-DEF-01)."
  }

  assert {
    condition     = length([for key, rule in aws_network_acl_rule.this : key if startswith(key, "telemetry_ingress-")]) == 2
    error_message = "telemetry_ingress must hold only its two final denies (CL-TEL-04)."
  }

  assert {
    condition     = aws_network_acl_rule.this["public_query-ingress-0"].cidr_block == "0.0.0.0/0" && aws_network_acl_rule.this["public_query-ingress-0"].from_port == 443 && aws_network_acl_rule.this["public_query-egress-0"].from_port == 1024
    error_message = "public_query must allow inbound 443 and outbound 1024 to 65535 only (CL-PUB-04)."
  }

  assert {
    condition     = aws_network_acl_rule.this["application-ingress-0"].cidr_block == "10.40.0.0/13" && aws_network_acl_rule.this["application-ingress-1"].cidr_block == "10.82.0.0/16" && aws_network_acl_rule.this["application-egress-2"].cidr_block == "0.0.0.0/0" && aws_network_acl_rule.this["application-egress-2"].from_port == 443
    error_message = "application must follow CL-APP-03, including the outbound 443 exception."
  }

  assert {
    condition     = toset([for key, rule in aws_network_acl_rule.this : rule.cidr_block if startswith(key, "object_storage-ingress-") && rule.from_port == 443]) == toset(["10.41.2.10/32", "10.42.2.10/32", "10.43.2.10/32", "10.82.0.0/16"])
    error_message = "object_storage must accept 443 only from the ground stations and the VPC (CL-DRN-04)."
  }

  assert {
    condition     = aws_network_acl_rule.this["data-ingress-0"].rule_action == "deny" && aws_network_acl_rule.this["data-ingress-0"].rule_number == 100 && aws_network_acl_rule.this["data-ingress-0"].cidr_block == "10.40.0.0/13" && aws_network_acl_rule.this["data-ingress-1"].from_port == 5432
    error_message = "data must deny every center at the lowest rule number and then allow the application tier on the store port (CL-DAT-01, CL-DAT-02)."
  }

  assert {
    condition     = toset([for key, rule in aws_network_acl_rule.this : rule.cidr_block if startswith(key, "administration-ingress-") && rule.from_port == 53]) == toset(["10.41.20.1/32", "10.42.20.1/32", "10.43.20.1/32"]) && aws_network_acl_rule.this["administration-egress-6"].from_port == 22
    error_message = "administration must follow CL-ADM-04."
  }

  assert {
    condition     = alltrue([for key, rule in aws_network_acl_rule.this : rule.rule_action == "deny" || rule.egress || rule.cidr_block != "0.0.0.0/0" || rule.from_port == 1024 || key == "public_query-ingress-0"])
    error_message = "Only public_query may accept new inbound connections from anywhere; other tiers accept only returns above 1023."
  }
}

run "empty_store_ports_leave_the_data_tier_denying" {
  command = plan

  variables {
    data_store_ports = []
  }

  assert {
    condition     = length([for key, rule in aws_network_acl_rule.this : key if startswith(key, "data-ingress-") && rule.rule_action == "allow"]) == 0
    error_message = "Without store ports the data tier must allow nothing inbound."
  }
}

run "firewall_that_is_not_a_host_address_is_rejected" {
  command = plan

  variables {
    collection_center_firewall_cidr_blocks = { cauca = "10.41.20.0/24", huila = "10.42.20.1/32", tolima = "10.43.20.1/32" }
  }

  expect_failures = [var.collection_center_firewall_cidr_blocks]
}

run "ground_station_for_an_unknown_center_is_rejected" {
  command = plan

  variables {
    collection_center_ground_station_cidr_blocks = { cauca = "10.41.2.10/32", huila = "10.42.2.10/32", boyaca = "10.44.2.10/32" }
  }

  expect_failures = [var.collection_center_ground_station_cidr_blocks]
}

run "invalid_store_port_is_rejected" {
  command = plan

  variables {
    data_store_ports = [70000]
  }

  expect_failures = [var.data_store_ports]
}

run "gateway_endpoints_serve_the_private_tiers" {
  command = plan

  # The mock gives every route table the same ID, so public_query gets its own to prove it is excluded.
  override_resource {
    target          = aws_route_table.this["public_query"]
    values          = { id = "rtb-pubq" }
    override_during = plan
  }

  assert {
    condition     = aws_vpc_endpoint.gateway["s3gw"].service_name == "com.amazonaws.us-east-1.s3" && aws_vpc_endpoint.gateway["ddbgw"].service_name == "com.amazonaws.us-east-1.dynamodb" && alltrue([for endpoint in values(aws_vpc_endpoint.gateway) : endpoint.vpc_endpoint_type == "Gateway"])
    error_message = "S3 and DynamoDB must use gateway endpoints."
  }

  assert {
    condition     = alltrue([for endpoint in values(aws_vpc_endpoint.gateway) : length(endpoint.route_table_ids) > 0 && !contains(endpoint.route_table_ids, "rtb-pubq")])
    error_message = "Gateway endpoints must attach to the private tiers and never to public_query."
  }

  assert {
    condition     = alltrue([for endpoint in values(aws_vpc_endpoint.gateway) : jsondecode(endpoint.policy).Statement[0].Condition.StringEquals["aws:ResourceOrgID"] == var.organization_id])
    error_message = "Gateway endpoint policies must admit only resources of the organization (CL-DAT-03)."
  }
}

run "interface_endpoints_live_only_in_three_tiers" {
  command = plan

  assert {
    condition     = toset(keys(aws_vpc_endpoint.interface)) == toset(["cogn", "exapi", "s3", "logs", "mon", "rola"]) && aws_vpc_endpoint.interface["exapi"].service_name == "com.amazonaws.us-east-1.execute-api"
    error_message = "Interface endpoints must follow interface_endpoints and the Region of the provider."
  }

  assert {
    condition     = alltrue([for endpoint in values(aws_vpc_endpoint.interface) : endpoint.vpc_endpoint_type == "Interface" && endpoint.private_dns_enabled && length(endpoint.security_group_ids) == 1 && length(endpoint.subnet_ids) > 0 && length(endpoint.tags["Name"]) <= 28])
    error_message = "Interface endpoints need private DNS, one security group, subnets and names within 28 characters."
  }

  assert {
    condition     = toset(keys(aws_security_group.endpoints)) == toset(["application", "object_storage", "administration"])
    error_message = "Only the three endpoint tiers may hold an endpoint security group; telemetry_ingress and drone_object_ingress hold none."
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.endpoints) == 6 && alltrue([for rule in values(aws_vpc_security_group_ingress_rule.endpoints) : rule.from_port == 443 && rule.to_port == 443 && rule.ip_protocol == "tcp" && contains(["10.82.0.0/16", "10.40.0.0/13"], rule.cidr_ipv4)])
    error_message = "Endpoint security groups must accept only HTTPS from the VPC and the collection centers."
  }
}

run "flow_logs_are_off_by_default" {
  command = plan

  assert {
    condition     = length(aws_flow_log.rejected) == 0
    error_message = "Without a destination no flow log is created."
  }
}

run "flow_logs_record_rejected_traffic" {
  command = plan

  variables {
    flow_logs = {
      destination_arn = "arn:aws:logs:us-east-1:000000000000:log-group:fixture"
      iam_role_arn    = "arn:aws:iam::000000000000:role/fixture"
    }
  }

  assert {
    condition     = length(aws_flow_log.rejected) == 1 && aws_flow_log.rejected[0].traffic_type == "REJECT"
    error_message = "A supplied destination must enable the flow log of rejected traffic (CL-DEF-02)."
  }
}

run "endpoint_in_telemetry_ingress_is_rejected" {
  command = plan

  variables {
    interface_endpoints = { iot = { service = "iot.data", tier = "telemetry_ingress" } }
  }

  expect_failures = [var.interface_endpoints]
}

run "endpoint_in_drone_object_ingress_is_rejected" {
  command = plan

  variables {
    interface_endpoints = { s3 = { service = "s3", tier = "drone_object_ingress" } }
  }

  expect_failures = [var.interface_endpoints]
}

run "long_endpoint_key_is_rejected" {
  command = plan

  variables {
    interface_endpoints = { rolesanywhere = { service = "rolesanywhere", tier = "administration" } }
  }

  expect_failures = [var.interface_endpoints]
}

run "malformed_organization_id_is_rejected" {
  command = plan

  variables {
    organization_id = "not-an-organization"
  }

  expect_failures = [var.organization_id]
}
