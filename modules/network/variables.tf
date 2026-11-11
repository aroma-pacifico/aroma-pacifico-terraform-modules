# Network pattern inputs. The consuming root supplies every value; there are no environment defaults.

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

variable "client" {
  description = "Client governance value from the root. At most 10 lowercase alphanumeric characters (PC-IAC-003)."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9]{1,10}$", var.client))
    error_message = "Client must be 1 to 10 lowercase alphanumeric characters."
  }
}

variable "collection_center_cidr_blocks" {
  description = "CIDR block of each collection center, keyed by center name. The VPC must not overlap any of them."
  type        = map(string)
  nullable    = false

  validation {
    condition     = length(var.collection_center_cidr_blocks) > 0 && alltrue([for cidr_block in values(var.collection_center_cidr_blocks) : can(cidrhost(cidr_block, 0))])
    error_message = "Provide at least one collection center, each with a valid IPv4 CIDR block."
  }
}

variable "collection_center_firewall_cidr_blocks" {
  description = "Host address (/32) of each collection center firewall, keyed like collection_center_cidr_blocks (CL-ADM-04)."
  type        = map(string)
  nullable    = false

  validation {
    condition     = alltrue([for cidr_block in values(var.collection_center_firewall_cidr_blocks) : can(cidrhost(cidr_block, 0)) && endswith(cidr_block, "/32")])
    error_message = "Every collection center firewall must be a single IPv4 address written as /32."
  }

  validation {
    condition     = length(setsubtract(keys(var.collection_center_firewall_cidr_blocks), keys(var.collection_center_cidr_blocks))) + length(setsubtract(keys(var.collection_center_cidr_blocks), keys(var.collection_center_firewall_cidr_blocks))) == 0
    error_message = "Firewall addresses must be keyed by exactly the collection centers of collection_center_cidr_blocks."
  }
}

variable "collection_center_ground_station_cidr_blocks" {
  description = "Host address (/32) of each collection center ground station, keyed like collection_center_cidr_blocks (CL-DRN-04)."
  type        = map(string)
  nullable    = false

  validation {
    condition     = alltrue([for cidr_block in values(var.collection_center_ground_station_cidr_blocks) : can(cidrhost(cidr_block, 0)) && endswith(cidr_block, "/32")])
    error_message = "Every ground station must be a single IPv4 address written as /32."
  }

  validation {
    condition     = length(setsubtract(keys(var.collection_center_ground_station_cidr_blocks), keys(var.collection_center_cidr_blocks))) + length(setsubtract(keys(var.collection_center_cidr_blocks), keys(var.collection_center_ground_station_cidr_blocks))) == 0
    error_message = "Ground station addresses must be keyed by exactly the collection centers of collection_center_cidr_blocks."
  }
}

variable "collection_center_summary_cidr_block" {
  description = "Single CIDR block that summarizes every present and future collection center, routed through the transit gateway."
  type        = string
  nullable    = false

  validation {
    condition     = can(cidrhost(var.collection_center_summary_cidr_block, 0))
    error_message = "Collection center summary must be a valid IPv4 CIDR block."
  }
}

variable "data_store_ports" {
  description = "TCP ports of the data store that the application tier may reach (CL-DAT-02). An empty list leaves the data tier denying everything."
  type        = list(number)
  nullable    = false

  validation {
    condition     = alltrue([for port in var.data_store_ports : port >= 1 && port <= 65535 && port == floor(port)])
    error_message = "Every data store port must be an integer between 1 and 65535."
  }
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

variable "flow_logs" {
  description = "CloudWatch Logs destination and IAM role for the flow log of rejected traffic, supplied by the security stack. Null disables flow logs."
  type = object({
    destination_arn = string
    iam_role_arn    = string
  })
  default = null

  validation {
    condition     = var.flow_logs == null || (startswith(var.flow_logs.destination_arn, "arn:aws:logs:") && startswith(var.flow_logs.iam_role_arn, "arn:aws:iam::"))
    error_message = "Flow logs need a CloudWatch Logs destination ARN and an IAM role ARN, or null."
  }
}

variable "interface_endpoints" {
  description = "Interface endpoints keyed by a short name (at most 6 characters, used in the physical name). Each names the service suffix and the tier that hosts it: application, object_storage or administration. telemetry_ingress and drone_object_ingress hold no endpoint (CL-TEL-04, PD-140)."
  type = map(object({
    service = string
    tier    = string
  }))
  nullable = false

  validation {
    condition     = alltrue([for key in keys(var.interface_endpoints) : can(regex("^[a-z0-9]{1,6}$", key))])
    error_message = "Interface endpoint keys must be 1 to 6 lowercase alphanumeric characters so that names stay within 28 characters."
  }

  validation {
    condition     = alltrue([for endpoint in values(var.interface_endpoints) : contains(["application", "object_storage", "administration"], endpoint.tier)])
    error_message = "Interface endpoints may only live in application, object_storage or administration."
  }

  validation {
    condition     = alltrue([for endpoint in values(var.interface_endpoints) : can(regex("^[a-z0-9][a-z0-9.-]*$", endpoint.service))])
    error_message = "Each service must be the lowercase service suffix, for example logs or execute-api."
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

variable "organization_id" {
  description = "AWS Organizations ID admitted by the gateway endpoint policies (aws:ResourceOrgID). Supplied by the root; never commit a real value to this public repository."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^o-[a-z0-9]{10,32}$", var.organization_id))
    error_message = "Organization ID must look like o-0123456789."
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

variable "subnets" {
  description = "Subnet CIDR blocks keyed by tier and then by Availability Zone slot (az1 to az3). az4 is reserved and rejected."
  type        = map(map(string))
  nullable    = false

  validation {
    condition     = length(setsubtract(keys(var.subnets), keys(local.tiers))) + length(setsubtract(keys(local.tiers), keys(var.subnets))) == 0
    error_message = "Subnets must define exactly the eight tiers of the addressing plan."
  }

  validation {
    condition     = alltrue([for azs in values(var.subnets) : length(setsubtract(keys(azs), local.az_slots)) + length(setsubtract(local.az_slots, keys(azs))) == 0])
    error_message = "Every tier must define exactly az1, az2 and az3. az4 is reserved and is never created."
  }

  validation {
    condition     = alltrue([for azs in values(var.subnets) : alltrue([for cidr_block in values(azs) : can(cidrhost(cidr_block, 0))])])
    error_message = "Every subnet CIDR block must be a valid IPv4 CIDR block."
  }

  validation {
    condition     = length(distinct(flatten([for azs in values(var.subnets) : values(azs)]))) == length(flatten([for azs in values(var.subnets) : values(azs)]))
    error_message = "Subnet CIDR blocks must be unique."
  }
}

variable "transit_gateway_id" {
  description = "Transit gateway of the network account. Null creates no route to the collection centers. The attachment is not created by this module."
  type        = string
  default     = null

  validation {
    condition     = var.transit_gateway_id == null || can(regex("^tgw-[0-9a-f]{8,17}$", var.transit_gateway_id))
    error_message = "Transit gateway ID must be null or look like tgw-0123456789abcdef0."
  }
}

variable "vpc_cidr_block" {
  description = "Primary IPv4 CIDR block of the environment VPC, inside 10.0.0.0/8. It must not overlap any collection center block."
  type        = string
  nullable    = false

  validation {
    condition     = try(tonumber(split(".", cidrhost(var.vpc_cidr_block, 0))[0]) == 10, false)
    error_message = "VPC CIDR block must be a valid IPv4 CIDR block inside 10.0.0.0/8."
  }
}
