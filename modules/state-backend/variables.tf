variable "client" {
  description = "Root governance client value; used to validate the root-built name."
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^[a-z0-9]+$", var.client))
    error_message = "Client must contain lowercase letters and digits only."
  }
}

variable "project" {
  description = "Root governance project value; used to validate the root-built name."
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^[a-z0-9]+$", var.project))
    error_message = "Project must contain lowercase letters and digits only."
  }
}

variable "environment" {
  description = "Exactly one environment owned by this invocation."
  type        = string
  nullable    = false
  validation {
    condition     = contains(["dev", "qa", "pdn"], var.environment)
    error_message = "Environment must be dev, qa, or pdn."
  }
}

variable "name_prefix" {
  description = "Root-built, globally unique bucket name and key-alias stem; no name is invented by this child."
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)+$", var.name_prefix)) && length(var.name_prefix) <= 28 && startswith(var.name_prefix, "${var.client}-${var.project}-${var.environment}-")
    error_message = "Supply a root-built client-project-environment-prefixed bucket name, lowercase kebab-case, at most 28 characters."
  }
}

variable "aws_context" {
  description = "Verified root account, partition and Region; labels do not discover or authenticate an AWS account."
  type = object({
    account_id = string
    partition  = string
    region     = string
  })
  nullable = false
  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_context.account_id)) && contains(["aws", "aws-us-gov", "aws-cn"], var.aws_context.partition) && can(regex("^[a-z]{2}(-[a-z]+)+-[0-9]+$", var.aws_context.region))
    error_message = "Supply a verified account identifier, supported partition and Region."
  }
}

variable "key_administrators" {
  description = "Nonempty explicit same-account IAM role ARNs approved for key administration; no root, wildcard or session principals."
  type        = set(string)
  nullable    = false
  validation {
    condition     = length(var.key_administrators) > 0 && alltrue([for arn in var.key_administrators : can(regex("^arn:${var.aws_context.partition}:iam::${var.aws_context.account_id}:role/[A-Za-z0-9+=,.@_/-]+$", arn))])
    error_message = "Key administrators must be explicit same-account IAM roles."
  }
}

variable "break_glass_role_arn_patterns" {
  description = "ARN patterns of the break-glass roles, the only principals allowed to schedule key deletion or disable the key. Wildcards are allowed because Identity Center role names carry a generated suffix. Never commit a real value."
  type        = list(string)
  nullable    = false

  validation {
    condition     = length(var.break_glass_role_arn_patterns) > 0 && alltrue([for pattern in var.break_glass_role_arn_patterns : startswith(pattern, "arn:") && pattern != "arn:*"])
    error_message = "Provide at least one break-glass ARN pattern that starts with arn: and is not a bare wildcard."
  }
}

variable "configuration_readers" {
  description = "Explicit same-account IAM roles permitted to inspect key configuration for plan/review, without changing policy or decrypting state."
  type        = set(string)
  nullable    = false
  validation {
    condition     = length(var.configuration_readers) > 0 && alltrue([for arn in var.configuration_readers : can(regex("^arn:${var.aws_context.partition}:iam::${var.aws_context.account_id}:role/[A-Za-z0-9+=,.@_/-]+$", arn))]) && length(setintersection(var.configuration_readers, var.key_administrators)) == 0
    error_message = "Configuration readers must be explicit same-account roles distinct from key administrators."
  }
}

variable "domain_access" {
  description = "Per-domain plan and optional write role ARNs; plans may write locks, never state. B06 owns the actual identities."
  type = map(object({
    plan_role_arns  = set(string)
    write_role_arns = optional(set(string), [])
  }))
  nullable = false
  validation {
    condition     = length(var.domain_access) > 0 && alltrue([for domain in keys(var.domain_access) : can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", domain))])
    error_message = "Provide at least one valid kebab-case lifecycle domain."
  }
  validation {
    condition = alltrue([for access in var.domain_access : length(access.plan_role_arns) > 0 && alltrue([
      for arn in setunion(access.plan_role_arns, access.write_role_arns) : can(regex("^arn:${var.aws_context.partition}:iam::${var.aws_context.account_id}:role/[A-Za-z0-9+=,.@_/-]+$", arn))
    ])])
    error_message = "Each domain needs explicit same-account plan roles and only explicit same-account write roles."
  }
  validation {
    condition     = length(setintersection(toset(flatten([for access in var.domain_access : tolist(access.plan_role_arns)])), toset(flatten([for access in var.domain_access : tolist(access.write_role_arns)])))) == 0
    error_message = "Plan and state-write identities must be different across all domains."
  }
  validation {
    condition     = length(setintersection(var.key_administrators, toset(flatten([for access in var.domain_access : tolist(access.plan_role_arns)])))) == 0
    error_message = "Key administrators must not be plan roles. An apply role may administer the key and write its own domain state."
  }
}

variable "additional_tags" {
  description = "Root-supplied governance metadata; Name cannot be overridden. No secret values."
  type        = map(string)
  nullable    = false
  validation {
    condition     = try(var.additional_tags.Client == var.client && var.additional_tags.Project == var.project && var.additional_tags.Environment == var.environment && trimspace(var.additional_tags.Owner) != "" && trimspace(var.additional_tags.CostCenter) != "", false)
    error_message = "Supply matching Client/Project/Environment and nonblank Owner/CostCenter tags."
  }
  validation {
    condition     = alltrue([for key, value in var.additional_tags : trimspace(key) != "" && value != null]) && (!contains(keys(var.additional_tags), "Name") || try(var.additional_tags.Name == var.name_prefix, false))
    error_message = "Tag keys/values must be valid and Name must match the root-built name."
  }
}
