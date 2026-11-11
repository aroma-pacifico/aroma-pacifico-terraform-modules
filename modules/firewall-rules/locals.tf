locals {
  # PC-IAC-003 caps a physical name at 28 characters. The longest suffix this module appends is
  # 8 characters ("-waf-lkp"), which leaves room for the 16 character prefix.
  max_name_prefix_length = 16

  governance_tags = merge({
    Client      = var.client
    Project     = var.project
    Environment = var.environment
  }, var.additional_tags)

  # The five customer-managed prefix lists of the firewall policy (section 5.1). Entries come from the
  # collection centers; a guest block is never an entry (validated on collection_centers).
  centers = values(var.collection_centers)

  prefix_lists = {
    cc_device_mgmt     = { code = "dev", entries = flatten([for center in local.centers : center.device_management_cidr_blocks]) }
    cc_firewalls       = { code = "fw", entries = [for center in local.centers : center.firewall_cidr_block] }
    cc_ground_stations = { code = "gnd", entries = [for center in local.centers : center.ground_station_cidr_block] }
    cc_logistics       = { code = "log", entries = [for center in local.centers : center.logistics_cidr_block] }
    cc_staff           = { code = "stf", entries = flatten([for center in local.centers : center.staff_cidr_blocks]) }
  }

  # Guest isolation (CC-GST rows of the policy, section 6): no admitted address may overlap a guest or
  # transporter block. Terraform has no CIDR containment function, so each block becomes a numeric
  # address range and two blocks overlap when their ranges intersect.
  admitted_cidr_blocks = {
    for center_key, center in var.collection_centers : center_key => concat(
      center.device_management_cidr_blocks,
      center.staff_cidr_blocks,
      [center.firewall_cidr_block, center.ground_station_cidr_block, center.logistics_cidr_block]
    )
  }

  cidr_ranges = {
    for cidr_block in distinct(flatten(concat(
      values(local.admitted_cidr_blocks),
      [for center in local.centers : center.guest_cidr_blocks]
      ))) : cidr_block => {
      first = sum([for index, octet in split(".", cidrhost(cidr_block, 0)) : tonumber(octet) * pow(256, 3 - index)])
      last  = sum([for index, octet in split(".", cidrhost(cidr_block, -1)) : tonumber(octet) * pow(256, 3 - index)])
    }
  }

  guest_overlaps = flatten([
    for center_key, center in var.collection_centers : [
      for guest in center.guest_cidr_blocks : [
        for admitted in local.admitted_cidr_blocks[center_key] : "${guest} overlaps ${admitted}"
        if local.cidr_ranges[guest].first <= local.cidr_ranges[admitted].last && local.cidr_ranges[admitted].first <= local.cidr_ranges[guest].last
      ]
    ]
  ])

  # Rules of the cloud policy table (section 5.2) that this module codes. validity and audit repeat the
  # table: audit is true when the column "Before production" says Audit (PD-125). The other permanent rules
  # (network ACLs, interface endpoint security groups, gateway endpoint policies, flow logs) live in the
  # network module; routes live in the association module.
  rule_catalog = merge(
    {
      "CL-ADM-01" = { group = "ADM", mechanism = "security group", resource = "resolver", validity = "permanent", audit = true }
      "CL-ADM-03" = { group = "ADM", mechanism = "security group", resource = "session_host", validity = "permanent", audit = true }
      "CL-DAT-02" = { group = "DAT", mechanism = "security group", resource = "data_store", validity = "permanent", audit = false }
      "CL-TEL-03" = { group = "TEL", mechanism = "web ACL", resource = "api", validity = "permanent", audit = true }
      "CL-PUB-01" = { group = "PUB", mechanism = "web ACL", resource = "lookup", validity = "permanent", audit = true }
    },
    var.api_endpoint == null ? {} : {
      "CL-APP-02" = { group = "APP", mechanism = "endpoint policy", resource = "api", validity = "permanent", audit = true }
    },
    var.drone_object_endpoint == null ? {} : {
      "CL-DRN-02" = { group = "DRN", mechanism = "endpoint policy", resource = "drone_objects", validity = "permanent", audit = true }
    },
    var.enable_cloudfront_origin_rule ? {
      "CL-PUB-03" = { group = "PUB", mechanism = "security group", resource = "load_balancer", validity = "permanent", audit = true }
    } : {},
    {
      for key, rule in var.temporary_rules : rule.rule_id => {
        group     = split("-", rule.rule_id)[1]
        mechanism = "security group"
        resource  = key
        validity  = "temporary"
        audit     = true
      }
    }
  )

  # Tags that make the permanent or temporary nature and the audit flag of a rule visible on the resource.
  rule_tags = {
    for rule_id, rule in local.rule_catalog : rule_id => {
      AuditBeforeProduction = tostring(rule.audit)
      FirewallRule          = rule_id
      Validity              = rule.validity
    }
  }

  # Ingress rules of the data store security group: one per application block and port (CL-DAT-02).
  data_store_rules = {
    for pair in setproduct(var.application_cidr_blocks, var.data_store_ports) :
    "${pair[0]}-${pair[1]}" => { cidr_block = pair[0], port = pair[1] }
  }

  # Interface endpoint policies (CL-APP-02, CL-DRN-02), present only when the root names the endpoint.
  endpoint_policies = merge(
    var.api_endpoint == null ? {} : {
      api = {
        endpoint_id = var.api_endpoint.endpoint_id
        statements = [{
          Effect    = "Allow"
          Principal = "*"
          Action    = ["execute-api:Invoke"]
          Resource  = var.api_endpoint.resource_arns
        }]
      }
    },
    var.drone_object_endpoint == null ? {} : {
      drone_objects = {
        endpoint_id = var.drone_object_endpoint.endpoint_id
        statements = [{
          Effect    = "Allow"
          Principal = "*"
          Action    = ["s3:PutObject", "s3:AbortMultipartUpload"]
          Resource  = ["${var.drone_object_endpoint.bucket_arn}/*"]
        }]
      }
    }
  )

  # Managed rule groups shared by both web ACLs (ASM-129), in the evaluation order of the design.
  managed_rule_groups = [
    { name = "AWSManagedRulesAmazonIpReputationList", key = "ip-reputation", priority = 10 },
    { name = "AWSManagedRulesKnownBadInputsRuleSet", key = "known-bad-inputs", priority = 20 },
    { name = "AWSManagedRulesCommonRuleSet", key = "common", priority = 30 },
  ]
}
