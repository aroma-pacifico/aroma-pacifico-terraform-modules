mock_provider "aws" {
  alias           = "project"
  override_during = plan

  mock_data "aws_ec2_managed_prefix_list" {
    defaults = { id = "pl-0cf0cf0cf0cf0cf0c" }
  }

  mock_resource "aws_ec2_managed_prefix_list" {
    defaults = { id = "pl-0a1a1a1a1a1a1a1a1" }
  }

  mock_resource "aws_security_group" {
    defaults = { id = "sg-0a1a1a1a1a1a1a1a1" }
  }
}

variables {
  client      = "fx"
  project     = "cf"
  environment = "pdn"
  name_prefix = "fx-cf-pdn"
  vpc_id      = "vpc-0a1a1a1a1a1a1a1a1"
  waf_scope   = "CLOUDFRONT"

  collection_centers = {
    cauca = {
      device_management_cidr_blocks = ["10.41.10.0/27", "10.41.10.32/28", "10.41.10.48/31"]
      firewall_cidr_block           = "10.41.20.1/32"
      ground_station_cidr_block     = "10.41.2.10/32"
      guest_cidr_blocks             = ["10.41.4.0/24", "10.41.5.0/24"]
      logistics_cidr_block          = "10.41.3.0/24"
      staff_cidr_blocks             = ["10.41.1.0/24", "10.41.2.0/24"]
    }
    huila = {
      device_management_cidr_blocks = ["10.42.10.0/27", "10.42.10.32/28", "10.42.10.48/31"]
      firewall_cidr_block           = "10.42.20.1/32"
      ground_station_cidr_block     = "10.42.2.10/32"
      guest_cidr_blocks             = ["10.42.4.0/24", "10.42.5.0/24"]
      logistics_cidr_block          = "10.42.3.0/24"
      staff_cidr_blocks             = ["10.42.1.0/24", "10.42.2.0/24"]
    }
    tolima = {
      device_management_cidr_blocks = ["10.43.10.0/27", "10.43.10.32/28", "10.43.10.48/31"]
      firewall_cidr_block           = "10.43.20.1/32"
      ground_station_cidr_block     = "10.43.2.10/32"
      guest_cidr_blocks             = ["10.43.4.0/24", "10.43.5.0/24"]
      logistics_cidr_block          = "10.43.3.0/24"
      staff_cidr_blocks             = ["10.43.1.0/24", "10.43.2.0/24"]
    }
  }

  application_cidr_blocks      = ["10.82.48.0/22", "10.82.52.0/22", "10.82.56.0/22"]
  data_store_ports             = [5432]
  lookup_allowed_path_prefixes = ["/assets/", "/s/"]
  lookup_rate_limit            = 100
  lookup_rate_scope_path       = "/s/"
  api_rate_limit               = 2000
}

run "prefix_lists_hold_the_center_addresses" {
  command = plan

  assert {
    condition     = length(aws_ec2_managed_prefix_list.this) == 5
    error_message = "The module must plan the five collection center prefix lists."
  }

  assert {
    condition     = length(aws_ec2_managed_prefix_list.this["cc_firewalls"].entry) == 3 && length(aws_ec2_managed_prefix_list.this["cc_staff"].entry) == 6 && length(aws_ec2_managed_prefix_list.this["cc_device_mgmt"].entry) == 9
    error_message = "The firewall list must hold 3 entries, the staff list 6 and the device management list 9."
  }

  assert {
    condition     = alltrue([for key, list in aws_ec2_managed_prefix_list.this : length(list.name) <= 28])
    error_message = "A prefix list name exceeds the 28 character cap of PC-IAC-003."
  }
}

run "no_guest_block_is_in_any_prefix_list" {
  command = plan

  assert {
    condition = alltrue(flatten([
      for key, list in aws_ec2_managed_prefix_list.this : [
        for entry in list.entry : !contains(flatten([for center in values(var.collection_centers) : center.guest_cidr_blocks]), entry.cidr)
      ]
    ]))
    error_message = "A guest block is present in a prefix list."
  }
}

run "session_host_only_leaves_towards_device_management" {
  command = plan

  assert {
    condition     = length(aws_vpc_security_group_egress_rule.session_host) == 2 && alltrue([for rule in values(aws_vpc_security_group_egress_rule.session_host) : contains([22, 443], rule.from_port) && rule.from_port == rule.to_port])
    error_message = "The session host must have exactly the egress rules for TCP 22 and TCP 443."
  }
}

run "resolver_answers_dns_over_tcp_and_udp" {
  command = plan

  assert {
    condition     = toset([for rule in values(aws_vpc_security_group_ingress_rule.resolver) : rule.ip_protocol]) == toset(["tcp", "udp"]) && alltrue([for rule in values(aws_vpc_security_group_ingress_rule.resolver) : rule.from_port == 53 && rule.to_port == 53])
    error_message = "The resolver security group must admit DNS on port 53 over TCP and UDP."
  }
}

run "data_store_admits_only_the_application_tier" {
  command = plan

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.data_store) == 3 && alltrue([for rule in values(aws_vpc_security_group_ingress_rule.data_store) : rule.from_port == 5432 && contains(var.application_cidr_blocks, rule.cidr_ipv4)])
    error_message = "The data store must admit port 5432 from the three application blocks and from nothing else."
  }
}

run "no_rule_opens_the_internet" {
  command = plan

  assert {
    condition = alltrue(concat(
      [for rule in values(aws_vpc_security_group_ingress_rule.data_store) : rule.cidr_ipv4 != "0.0.0.0/0"],
      [for rule in values(aws_vpc_security_group_ingress_rule.resolver) : rule.cidr_ipv4 == null]
    ))
    error_message = "A security group rule opens 0.0.0.0/0."
  }
}

run "lookup_web_acl_blocks_by_default_and_orders_its_rules" {
  command = plan

  assert {
    condition     = length(aws_wafv2_web_acl.lookup.default_action[0].block) == 1 && length(aws_wafv2_web_acl.lookup.default_action[0].allow) == 0
    error_message = "The public lookup web ACL must default to Block."
  }

  assert {
    condition     = jsonencode(sort([for rule in aws_wafv2_web_acl.lookup.rule : format("%03d-%s", rule.priority, rule.name)])) == jsonencode(["010-ip-reputation", "020-known-bad-inputs", "030-common", "040-rate-per-ip", "050-allow-read"])
    error_message = "The lookup rules must run reputation, bad inputs, common, rate and allow, in that order."
  }

  assert {
    condition     = one([for rule in aws_wafv2_web_acl.lookup.rule : rule if rule.name == "rate-per-ip"]).statement[0].rate_based_statement[0].limit == 100
    error_message = "The lookup rate limit must be the value supplied by the root."
  }
}

run "api_web_acl_allows_by_default_with_a_rate_limit" {
  command = plan

  assert {
    condition     = length(aws_wafv2_web_acl.api.default_action[0].allow) == 1 && one([for rule in aws_wafv2_web_acl.api.rule : rule if rule.name == "rate-per-ip"]).statement[0].rate_based_statement[0].limit == 2000
    error_message = "The API web ACL must default to Allow and carry the supplied rate limit."
  }
}

run "catalog_marks_every_rule_permanent_and_skips_the_load_balancer" {
  command = plan

  assert {
    condition     = toset(keys(output.rule_catalog)) == toset(["CL-ADM-01", "CL-ADM-03", "CL-DAT-02", "CL-PUB-01", "CL-TEL-03"])
    error_message = "Without endpoints, temporary rules or a load balancer the catalog must hold five rules."
  }

  assert {
    condition     = alltrue([for rule in values(output.rule_catalog) : rule.validity == "permanent"])
    error_message = "Every rule of the default plan must be permanent."
  }

  assert {
    condition     = !contains(keys(output.security_group_ids), "load_balancer")
    error_message = "The load balancer security group must not exist by default."
  }

  assert {
    condition     = aws_security_group.resolver.tags["Validity"] == "permanent" && aws_security_group.resolver.tags["AuditBeforeProduction"] == "true" && aws_security_group.data_store.tags["AuditBeforeProduction"] == "false"
    error_message = "Rule tags must carry the validity and the audit flag of the policy table."
  }
}

run "cloudfront_origin_rule_creates_the_load_balancer_group" {
  command = plan

  variables {
    enable_cloudfront_origin_rule = true
  }

  assert {
    condition     = contains(keys(output.security_group_ids), "load_balancer") && contains(keys(output.rule_catalog), "CL-PUB-03")
    error_message = "Enabling the CloudFront origin rule must create the load balancer group and catalog CL-PUB-03."
  }
}

run "endpoint_policies_allow_only_the_designed_actions" {
  command = plan

  variables {
    api_endpoint = {
      endpoint_id   = "vpce-0a1a1a1a1a1a1a1a1"
      resource_arns = ["arn:aws:execute-api:us-east-1:*:abcdef1234/*"]
    }
    drone_object_endpoint = {
      bucket_arn  = "arn:aws:s3:::fx-cf-pdn-drone-objects"
      endpoint_id = "vpce-0b2b2b2b2b2b2b2b2"
    }
  }

  assert {
    condition     = jsondecode(aws_vpc_endpoint_policy.this["api"].policy).Statement[0].Action == ["execute-api:Invoke"]
    error_message = "The API endpoint policy must allow only execute-api:Invoke."
  }

  assert {
    condition     = jsondecode(aws_vpc_endpoint_policy.this["drone_objects"].policy).Statement[0].Action == ["s3:PutObject", "s3:AbortMultipartUpload"] && jsondecode(aws_vpc_endpoint_policy.this["drone_objects"].policy).Statement[0].Resource == ["arn:aws:s3:::fx-cf-pdn-drone-objects/*"]
    error_message = "The drone endpoint policy must allow only writes to the drone object bucket."
  }

  assert {
    condition     = contains(keys(output.rule_catalog), "CL-APP-02") && contains(keys(output.rule_catalog), "CL-DRN-02")
    error_message = "Attaching the endpoint policies must add CL-APP-02 and CL-DRN-02 to the catalog."
  }
}

run "temporary_rule_is_tagged_temporary_with_its_removal_condition" {
  command = plan

  variables {
    temporary_rules = {
      qa_logistics = {
        from_port          = 443
        protocol           = "tcp"
        removal_condition  = "center acceptance tests are signed off"
        rule_id            = "CL-LNK-05"
        security_group_id  = "sg-0d4d4d4d4d4d4d4d4"
        source_prefix_list = "cc_logistics"
        to_port            = 443
      }
    }
  }

  assert {
    condition     = output.rule_catalog["CL-LNK-05"].validity == "temporary" && aws_vpc_security_group_ingress_rule.temporary["qa_logistics"].tags["Validity"] == "temporary"
    error_message = "A temporary rule must be cataloged and tagged as temporary."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.temporary["qa_logistics"].tags["RemovalCondition"] == "center acceptance tests are signed off"
    error_message = "A temporary rule must carry its removal condition."
  }
}

run "temporary_rule_without_a_valid_removal_condition_is_rejected" {
  command = plan

  variables {
    temporary_rules = {
      qa_logistics = {
        from_port          = 443
        protocol           = "tcp"
        removal_condition  = "later, maybe"
        rule_id            = "CL-LNK-05"
        security_group_id  = "sg-0d4d4d4d4d4d4d4d4"
        source_prefix_list = "cc_logistics"
        to_port            = 443
      }
    }
  }

  expect_failures = [var.temporary_rules]
}

run "guest_block_overlapping_an_admitted_address_is_rejected" {
  command = plan

  variables {
    collection_centers = {
      cauca = {
        device_management_cidr_blocks = ["10.41.10.0/27"]
        firewall_cidr_block           = "10.41.20.1/32"
        ground_station_cidr_block     = "10.41.2.10/32"
        guest_cidr_blocks             = ["10.41.3.0/24"]
        logistics_cidr_block          = "10.41.3.0/24"
        staff_cidr_blocks             = ["10.41.1.0/24"]
      }
    }
  }

  expect_failures = [aws_ec2_managed_prefix_list.this]
}

run "invalid_waf_scope_is_rejected" {
  command = plan

  variables {
    waf_scope = "GLOBAL"
  }

  expect_failures = [var.waf_scope]
}

run "name_prefix_longer_than_sixteen_characters_is_rejected" {
  command = plan

  variables {
    name_prefix = "fx-cf-pdn-too-long"
  }

  expect_failures = [var.name_prefix]
}
