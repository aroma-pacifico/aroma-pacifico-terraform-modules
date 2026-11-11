variable "api_endpoint" {
  description = "Private API endpoint and the API ARNs it may invoke, or null."
  type = object({
    endpoint_id   = string
    resource_arns = list(string)
  })
  default = null
}

variable "api_rate_limit" {
  description = "Synthetic requests per source IP in a 5-minute window for the API front door."
  type        = number
}

variable "application_cidr_blocks" {
  description = "Synthetic application tier subnet blocks."
  type        = list(string)
}

variable "client" {
  description = "Synthetic client value."
  type        = string
}

variable "collection_centers" {
  description = "Synthetic addresses of each collection center, from the addressing plan pattern."
  type = map(object({
    device_management_cidr_blocks = list(string)
    firewall_cidr_block           = string
    ground_station_cidr_block     = string
    guest_cidr_blocks             = list(string)
    logistics_cidr_block          = string
    staff_cidr_blocks             = list(string)
  }))
}

variable "data_store_ports" {
  description = "Fixture TCP ports of the data store; the real port comes from the data design."
  type        = list(number)
}

variable "drone_object_endpoint" {
  description = "Drone object endpoint and bucket ARN, or null."
  type = object({
    bucket_arn  = string
    endpoint_id = string
  })
  default = null
}

variable "enable_cloudfront_origin_rule" {
  description = "Creates the load balancer security group of CL-PUB-03."
  type        = bool
  default     = false
}

variable "environment" {
  description = "Environment code: dev, qa or pdn."
  type        = string
}

variable "lookup_allowed_path_prefixes" {
  description = "Path prefixes the lookup allow rule admits."
  type        = list(string)
}

variable "lookup_rate_limit" {
  description = "Requests per source IP in a 5-minute window for the public lookup (ASM-155)."
  type        = number
}

variable "lookup_rate_scope_path" {
  description = "Path prefix to which the lookup rate rule is scoped down."
  type        = string
}

variable "project" {
  description = "Synthetic project value."
  type        = string
}

variable "region" {
  description = "Region of the sample provider."
  type        = string
}

variable "temporary_rules" {
  description = "Temporary rules; empty in the sample."
  type = map(object({
    from_port          = number
    protocol           = string
    removal_condition  = string
    rule_id            = string
    security_group_id  = string
    source_prefix_list = string
    to_port            = number
  }))
  default = {}
}

variable "vpc_id" {
  description = "Synthetic VPC ID standing in for the network stack output."
  type        = string
}

variable "waf_scope" {
  description = "CLOUDFRONT or REGIONAL."
  type        = string
}
