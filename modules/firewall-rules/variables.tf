# Firewall rules inputs. The consuming root supplies every value; there are no environment defaults.

variable "additional_tags" {
  description = "Extra non-secret tags merged into every taggable resource."
  type        = map(string)
  default     = {}
  nullable    = false

  validation {
    condition     = alltrue([for key, value in var.additional_tags : trimspace(key) != "" && value != null])
    error_message = "Additional tag keys must be nonempty and values must not be null."
  }
}

variable "api_endpoint" {
  description = "Interface endpoint of the platform's private APIs and the API ARNs it may invoke (CL-APP-02). Null attaches no policy."
  type = object({
    endpoint_id   = string
    resource_arns = list(string)
  })
  default = null

  validation {
    condition     = var.api_endpoint == null ? true : length(var.api_endpoint.resource_arns) > 0
    error_message = "The API endpoint policy must name at least one API ARN."
  }
}

variable "api_rate_limit" {
  description = "Requests per source IP in a 5-minute window above which the public application API front door blocks (CL-TEL-03). The design gives no value, so the root supplies it."
  type        = number
  nullable    = false

  validation {
    condition     = var.api_rate_limit >= 10 && var.api_rate_limit <= 20000000 && floor(var.api_rate_limit) == var.api_rate_limit
    error_message = "The API rate limit must be a whole number from 10 to 20000000, the range AWS WAF accepts."
  }
}

variable "application_cidr_blocks" {
  description = "CIDR blocks of the application tier subnets, the only sources admitted by the data store security group (CL-DAT-02)."
  type        = list(string)
  default     = []
  nullable    = false

  validation {
    condition     = alltrue([for cidr_block in var.application_cidr_blocks : can(cidrhost(cidr_block, 0))])
    error_message = "Every application CIDR block must be a valid IPv4 CIDR block."
  }
}

variable "client" {
  description = "Client governance value from the root. At most 10 lowercase alphanumeric characters (PC-IAC-003)."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9]{1,10}$", var.client))
    error_message = "Client must be 1 to 10 lowercase alphanumeric characters."
  }
}

variable "collection_centers" {
  description = "Addresses of each collection center, keyed by center name. They feed the five customer-managed prefix lists of the firewall policy (section 5.1): firewall host, staff blocks, logistics block, ground station host and device management blocks. guest_cidr_blocks lists the visitor and transporter blocks, which must never appear in a prefix list."
  type = map(object({
    device_management_cidr_blocks = list(string)
    firewall_cidr_block           = string
    ground_station_cidr_block     = string
    guest_cidr_blocks             = list(string)
    logistics_cidr_block          = string
    staff_cidr_blocks             = list(string)
  }))
  nullable = false

  validation {
    condition     = length(var.collection_centers) > 0
    error_message = "At least one collection center is required."
  }

  validation {
    condition = alltrue(flatten([
      for center in values(var.collection_centers) : concat(
        [for cidr_block in concat(center.device_management_cidr_blocks, center.guest_cidr_blocks, center.staff_cidr_blocks) : can(cidrhost(cidr_block, 0))],
        [can(cidrhost(center.firewall_cidr_block, 0)), can(cidrhost(center.ground_station_cidr_block, 0)), can(cidrhost(center.logistics_cidr_block, 0))]
      )
    ]))
    error_message = "Every collection center address must be a valid IPv4 CIDR block."
  }
}

variable "data_store_ports" {
  description = "TCP ports of the data store that the application tier may reach (CL-DAT-02). An empty list leaves the data store security group without ingress rules."
  type        = list(number)
  default     = []
  nullable    = false

  validation {
    condition     = alltrue([for port in var.data_store_ports : port >= 1 && port <= 65535 && floor(port) == port])
    error_message = "Every data store port must be a whole number from 1 to 65535."
  }
}

variable "drone_object_endpoint" {
  description = "Amazon S3 interface endpoint of the object_storage tier and the drone object bucket ARN it may write to (CL-DRN-02). Null attaches no policy."
  type = object({
    bucket_arn  = string
    endpoint_id = string
  })
  default = null

  validation {
    condition     = var.drone_object_endpoint == null ? true : can(regex("^arn:aws[a-z-]*:s3:::[a-z0-9.-]{3,63}$", var.drone_object_endpoint.bucket_arn))
    error_message = "The drone object bucket ARN must be an S3 bucket ARN without an object path."
  }
}

variable "enable_cloudfront_origin_rule" {
  description = "Creates the load balancer security group that admits only the CloudFront origin-facing prefix list (CL-PUB-03). Enable it only if the public lookup chooses a load balancer (PD-051)."
  type        = bool
  default     = false
  nullable    = false
}

variable "environment" {
  description = "Environment code: dev, qa or pdn."
  type        = string
  nullable    = false

  validation {
    condition     = contains(["dev", "qa", "pdn"], var.environment)
    error_message = "Environment must be dev, qa or pdn."
  }
}

variable "lookup_allowed_path_prefixes" {
  description = "URI path prefixes of the public lookup that the allow rule admits for GET and HEAD, besides the exact path / (CL-PUB-01), for example the assets and sack prefixes."
  type        = list(string)
  nullable    = false

  validation {
    condition     = length(var.lookup_allowed_path_prefixes) > 0 && alltrue([for prefix in var.lookup_allowed_path_prefixes : startswith(prefix, "/") && endswith(prefix, "/")])
    error_message = "Provide at least one path prefix, and each must start and end with a slash."
  }
}

variable "lookup_rate_limit" {
  description = "Requests per source IP in a 5-minute window above which the public lookup front door blocks (CL-PUB-01, ASM-155)."
  type        = number
  nullable    = false

  validation {
    condition     = var.lookup_rate_limit >= 10 && var.lookup_rate_limit <= 20000000 && floor(var.lookup_rate_limit) == var.lookup_rate_limit
    error_message = "The lookup rate limit must be a whole number from 10 to 20000000, the range AWS WAF accepts."
  }
}

variable "lookup_rate_scope_path" {
  description = "URI path prefix to which the rate-based rule of the public lookup is scoped down (CL-PUB-01), for example the sack lookup prefix."
  type        = string
  nullable    = false

  validation {
    condition     = startswith(var.lookup_rate_scope_path, "/") && endswith(var.lookup_rate_scope_path, "/")
    error_message = "The rate scope path must start and end with a slash."
  }
}

variable "name_prefix" {
  description = "Prefix of every physical name, normally client-project-environment. At most 16 characters so that names stay within the 28 character cap of PC-IAC-003."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.name_prefix)) && length(var.name_prefix) <= local.max_name_prefix_length
    error_message = "Name prefix must be lowercase alphanumeric words joined by hyphens, at most 16 characters (PC-IAC-003 28 character cap)."
  }
}

variable "project" {
  description = "Project governance value from the root. At most 15 lowercase alphanumeric characters (PC-IAC-003)."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9]{1,15}$", var.project))
    error_message = "Project must be 1 to 15 lowercase alphanumeric characters."
  }
}

variable "temporary_rules" {
  description = "Temporary ingress rules keyed by a short name (CL-LNK-05 style). Each opens one protocol and port range from one of the five prefix lists to a security group, and must state the condition that removes it. They are tagged Validity=temporary so the pre-production audit finds them."
  type = map(object({
    from_port          = number
    protocol           = string
    removal_condition  = string
    rule_id            = string
    security_group_id  = string
    source_prefix_list = string
    to_port            = number
  }))
  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for rule in values(var.temporary_rules) : contains(["cc_device_mgmt", "cc_firewalls", "cc_ground_stations", "cc_logistics", "cc_staff"], rule.source_prefix_list)])
    error_message = "A temporary rule source must be one of cc_device_mgmt, cc_firewalls, cc_ground_stations, cc_logistics or cc_staff."
  }

  validation {
    condition     = alltrue([for rule in values(var.temporary_rules) : can(regex("^CL-[A-Z]{3}-[0-9]{2}$", rule.rule_id))])
    error_message = "A temporary rule ID must follow the policy table format, for example CL-LNK-05."
  }

  validation {
    condition     = alltrue([for rule in values(var.temporary_rules) : can(regex("^[A-Za-z0-9 _.:/=+@-]{10,255}$", rule.removal_condition))])
    error_message = "The removal condition must be 10 to 255 characters and use only characters that AWS tag values accept (no commas)."
  }

  validation {
    condition     = alltrue([for rule in values(var.temporary_rules) : contains(["tcp", "udp"], rule.protocol) && rule.from_port >= 1 && rule.to_port <= 65535 && rule.from_port <= rule.to_port])
    error_message = "A temporary rule must use tcp or udp and a valid port range."
  }
}

variable "vpc_id" {
  description = "ID of the environment VPC, read from the network stack."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^vpc-[a-z0-9]+$", var.vpc_id))
    error_message = "VPC ID must look like vpc-0123456789abcdef0."
  }
}

variable "waf_scope" {
  description = "Scope of the web ACLs: CLOUDFRONT for a CloudFront front door (created in us-east-1) or REGIONAL for a regional resource."
  type        = string
  nullable    = false

  validation {
    condition     = contains(["CLOUDFRONT", "REGIONAL"], var.waf_scope)
    error_message = "WAF scope must be CLOUDFRONT or REGIONAL."
  }
}
