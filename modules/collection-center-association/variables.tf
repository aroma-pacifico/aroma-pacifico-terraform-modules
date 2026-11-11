variable "client" {
  description = "Root-supplied client governance value."
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^[a-z0-9]{1,10}$", var.client))
    error_message = "Client must contain 1 to 10 lowercase alphanumeric characters."
  }
}
variable "project" {
  description = "Root-supplied project governance value."
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^[a-z0-9]{1,15}$", var.project))
    error_message = "Project must contain 1 to 15 lowercase alphanumeric characters."
  }
}
variable "environment" {
  description = "Permanent association context; temporary QA routing is a separate B07 responsibility."
  type        = string
  nullable    = false
  validation {
    condition     = var.environment == "pdn"
    error_message = "Permanent connections are allowed only in pdn; dev is isolated and qa requires a separately approved temporary routing composition."
  }
}
variable "name_prefix" {
  description = "Root-built client-project-environment-resource prefix, at most 20 characters."
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)+$", var.name_prefix)) && length(var.name_prefix) <= 20 && startswith(var.name_prefix, "${var.client}-${var.project}-${var.environment}-")
    error_message = "Supply a lowercase governance prefix matching this environment, at most 20 characters."
  }
}
variable "additional_tags" {
  description = "Non-secret root governance tags; protected identity tags take precedence."
  type        = map(string)
  default     = {}
  nullable    = false
  validation {
    condition     = alltrue([for k, v in var.additional_tags : trimspace(k) != "" && v != null])
    error_message = "Additional tags must have nonempty keys and non-null values."
  }
}
variable "center" {
  description = "Exactly one root-approved center and its canonical departmental /16; never an inventory."
  type        = object({ key = string, cidr_block = string })
  nullable    = false
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,14}$", var.center.key)) && can(cidrnetmask(var.center.cidr_block)) && try(split("/", var.center.cidr_block)[1] == "16" && cidrhost(var.center.cidr_block, 0) == split("/", var.center.cidr_block)[0], false)
    error_message = "Supply one named center with a canonical IPv4 /16. The root owns the approved departmental catalog."
  }
}
variable "network" {
  description = "B04 outputs: vpc_id, vpc_cidr_block and transit_attachment_subnet_ids, plus explicit environment and owner context."
  type        = object({ environment = string, account_id = string, vpc_id = string, vpc_cidr_block = string, transit_attachment_subnet_ids = list(string) })
  nullable    = false
  validation {
    condition     = var.network.environment == var.environment && can(regex("^[0-9]{12}$", var.network.account_id)) && can(regex("^vpc-[0-9a-f]{8,17}$", var.network.vpc_id)) && can(cidrnetmask(var.network.vpc_cidr_block))
    error_message = "B04 references must be valid IPv4 VPC references in the selected environment and an explicit owner account."
  }
  validation {
    condition     = length(var.network.transit_attachment_subnet_ids) > 0 && length(var.network.transit_attachment_subnet_ids) <= 3 && length(distinct(var.network.transit_attachment_subnet_ids)) == length(var.network.transit_attachment_subnet_ids) && alltrue([for id in var.network.transit_attachment_subnet_ids : can(regex("^subnet-[0-9a-f]{8,17}$", id))])
    error_message = "Supply one to three distinct B04 transit subnet references, one per Availability Zone."
  }
  validation {
    condition = try(alltrue([for ranges in [[for cidr in [var.network.vpc_cidr_block, var.center.cidr_block] : {
      first = sum([for i, octet in split(".", cidrhost(cidr, 0)) : tonumber(octet) * pow(256, 3 - i)])
      last  = sum([for i, octet in split(".", cidrhost(cidr, -1)) : tonumber(octet) * pow(256, 3 - i)])
    }]] : ranges[0].last < ranges[1].first || ranges[1].last < ranges[0].first]), false)
    error_message = "The VPC and selected department CIDRs must not overlap."
  }
}
variable "hub" {
  description = "Externally owned shared Transit Gateway and public ACM private-certificate reference; never a private key or PSK."
  type        = object({ account_id = string, region = string, transit_gateway_id = string, customer_certificate_arn = string })
  nullable    = false
  validation {
    condition     = can(regex("^[0-9]{12}$", var.hub.account_id)) && can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.hub.region)) && can(regex("^tgw-[0-9a-f]{8,17}$", var.hub.transit_gateway_id))
    error_message = "An explicit network-account hub and Region are required; no Transit Gateway is created here."
  }
  validation {
    condition     = can(regex("^arn:aws:acm:${var.hub.region}:${var.hub.account_id}:certificate/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.hub.customer_certificate_arn))
    error_message = "Supply a same-Region network-account ACM certificate reference for the customer gateway."
  }
}
