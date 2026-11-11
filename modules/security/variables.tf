# Security baseline inputs. The consuming root supplies every value; there are no environment defaults.

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

variable "break_glass_role_arn_patterns" {
  description = "ARN patterns of the break-glass roles, the only principals allowed to schedule key deletion or disable a key. Wildcards are allowed because Identity Center role names carry a generated suffix. Never commit a real value."
  type        = list(string)
  nullable    = false

  validation {
    condition     = length(var.break_glass_role_arn_patterns) > 0 && alltrue([for pattern in var.break_glass_role_arn_patterns : startswith(pattern, "arn:") && pattern != "arn:*"])
    error_message = "Provide at least one break-glass ARN pattern that starts with arn: and is not a bare wildcard."
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

variable "environment" {
  description = "Environment code: dev, qa or pdn."
  type        = string
  nullable    = false

  validation {
    condition     = contains(["dev", "qa", "pdn"], var.environment)
    error_message = "Environment must be dev, qa or pdn."
  }
}

variable "field_sms_configuration" {
  description = "SNS role and external ID that let the field user pool send one-time codes by SMS to farmers and transporters. Null leaves the pool with email codes only. The external ID is a secret supplied by the root."
  type = object({
    sns_caller_arn = string
    external_id    = string
  })
  default   = null
  sensitive = true

  validation {
    condition     = var.field_sms_configuration == null || (startswith(var.field_sms_configuration.sns_caller_arn, "arn:") && trimspace(var.field_sms_configuration.external_id) != "")
    error_message = "SMS configuration needs an IAM role ARN and a nonempty external ID."
  }
}

variable "key_administrator_arns" {
  description = "IAM principals that administer every key of the environment, normally the apply role of the security stack. They manage keys but get no use of the key material. Never commit a real value."
  type        = list(string)
  nullable    = false

  validation {
    condition     = length(var.key_administrator_arns) > 0 && alltrue([for arn in var.key_administrator_arns : startswith(arn, "arn:") && !strcontains(arn, "*")])
    error_message = "Provide at least one explicit administrator ARN, without wildcards."
  }
}

variable "key_user_arns" {
  description = "Principals allowed to use each key, keyed by data class (telemetry, objects, records, personal, logs, state, public_view, restricted). Each ARN must be explicit. An absent class gets no user, and restricted should stay empty (ASM-165)."
  type        = map(list(string))
  default     = {}
  nullable    = false

  validation {
    condition     = length(setsubtract(keys(var.key_user_arns), ["telemetry", "objects", "records", "personal", "logs", "state", "public_view", "restricted"])) == 0
    error_message = "Key user classes must be among telemetry, objects, records, personal, logs, state, public_view and restricted."
  }

  validation {
    condition     = alltrue([for arns in values(var.key_user_arns) : alltrue([for arn in arns : startswith(arn, "arn:") && !strcontains(arn, "*")])])
    error_message = "Every key user must be an explicit ARN without wildcards."
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

variable "protected_bucket_arns" {
  description = "S3 bucket ARNs that must refuse plain HTTP and TLS older than 1.2. The module renders the policy statements as an output; the bucket owner attaches them. Empty renders nothing."
  type        = set(string)
  default     = []
  nullable    = false

  validation {
    condition     = alltrue([for arn in var.protected_bucket_arns : can(regex("^arn:[a-z-]+:s3:::[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", arn))])
    error_message = "Every protected bucket must be a bucket ARN (arn:<partition>:s3:::<name>), not an object ARN."
  }
}
