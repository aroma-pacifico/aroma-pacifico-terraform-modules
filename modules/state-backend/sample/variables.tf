variable "account_id" {
  description = "Synthetic 12-digit account identifier of the fixture. Real values come from the private root."
  type        = string
}

variable "break_glass_role_arn_patterns" {
  description = "Synthetic break-glass role ARN patterns."
  type        = list(string)
}

variable "client" {
  description = "Synthetic client value."
  type        = string
}

variable "configuration_readers" {
  description = "Synthetic read-only configuration role ARNs."
  type        = set(string)
}

variable "cost_center" {
  description = "Synthetic cost-center tag value."
  type        = string
}

variable "domain_access" {
  description = "Synthetic plan and write role ARNs per state domain."
  type = map(object({
    plan_role_arns  = set(string)
    write_role_arns = optional(set(string), [])
  }))

  validation {
    condition     = toset(keys(var.domain_access)) == toset(["network", "security", "workload", "state-backend"])
    error_message = "The composition must cover all four approved state domains."
  }
}

variable "environment" {
  description = "Environment code: dev, qa or pdn."
  type        = string

  validation {
    condition     = contains(["dev", "qa", "pdn"], var.environment)
    error_message = "Use one approved environment: dev, qa or pdn."
  }
}

variable "key_administrators" {
  description = "Synthetic key administrator role ARNs."
  type        = set(string)
}

variable "owner" {
  description = "Synthetic owner tag value."
  type        = string
}

variable "project" {
  description = "Synthetic project value."
  type        = string
}

variable "region" {
  description = "AWS Region of the sample provider."
  type        = string

  validation {
    condition     = var.region == "us-east-1"
    error_message = "Use the primary us-east-1 Region."
  }
}

variable "resource_key" {
  description = "Short suffix that completes the bucket name."
  type        = string
}
