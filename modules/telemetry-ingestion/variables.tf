# Telemetry ingestion inputs. The consuming root supplies every environment value; only the documented
# design values (error queue retention, attribute names) carry a default.

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

variable "environment" {
  description = "Environment code: dev, qa or pdn."
  type        = string
  nullable    = false

  validation {
    condition     = contains(["dev", "qa", "pdn"], var.environment)
    error_message = "Environment must be dev, qa or pdn."
  }
}

variable "error_queue_retention_days" {
  description = "Days the rule error queue keeps a failed message. The inference design keeps dead-letter messages 14 days, the longest an SQS queue allows."
  type        = number
  default     = 14
  nullable    = false

  validation {
    condition     = var.error_queue_retention_days >= 1 && var.error_queue_retention_days <= 14 && floor(var.error_queue_retention_days) == var.error_queue_retention_days
    error_message = "Error queue retention must be a whole number of days from 1 to 14."
  }
}

variable "kms_key_arns" {
  description = "Customer-managed key ARNs keyed by data class, the kms_key_arns output of the security module. The telemetry key encrypts the telemetry table and the rule error queue; the logs key encrypts the IoT Core log group."
  type        = map(string)
  nullable    = false

  validation {
    condition     = alltrue([for class in ["telemetry", "logs"] : can(regex("^arn:aws[a-z-]*:kms:[a-z0-9-]+:[0-9]{12}:key/.+$", lookup(var.kms_key_arns, class, "")))])
    error_message = "kms_key_arns must contain the telemetry and logs classes as KMS key ARNs."
  }
}

variable "log_retention_days" {
  description = "Retention of the AWSIotLogsV2 log group, in days. A CloudWatch Logs retention value; the observability design uses 365."
  type        = number
  nullable    = false

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "Log retention must be a value that CloudWatch Logs accepts and must not be 0 (never expire)."
  }
}

variable "logging_role_arn" {
  description = "ARN of the role that AWS IoT Core assumes to write its logs (PD-073). The security stack creates it; this module creates no IAM role."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^arn:aws[a-z-]*:iam::[0-9]{12}:role/.+$", var.logging_role_arn))
    error_message = "The logging role must be an IAM role ARN."
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

variable "retention_days" {
  description = "Days a stored reading is kept before DynamoDB time to live deletes it. The case statement fixes 5 years for readings; the root states the day count, counted from the rule receive time."
  type        = number
  nullable    = false

  validation {
    condition     = var.retention_days >= 1 && floor(var.retention_days) == var.retention_days
    error_message = "Retention must be a whole number of days, at least 1."
  }
}

variable "rule_role_arn" {
  description = "ARN of the role that the topic rule assumes for its actions: PutItem on the telemetry table, SendMessage on the threshold queue and on the rule error queue, and use of the telemetry and records keys. The security stack creates it; this module creates no IAM role."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^arn:aws[a-z-]*:iam::[0-9]{12}:role/.+$", var.rule_role_arn))
    error_message = "The rule role must be an IAM role ARN."
  }
}

variable "telemetry_attributes" {
  description = "Names of the table attributes. node_id is derived from the topic, which the device policy ties to the certificate; reading_at is the original reading timestamp that the device publishes and is the sort key; received_at is the rule receive time in epoch milliseconds; expires_at is the time to live in epoch seconds. reading_at_type is S for an ISO 8601 UTC string or N for a number."
  type = object({
    node_id         = optional(string, "node_id")
    reading_at      = optional(string, "reading_at")
    reading_at_type = optional(string, "S")
    received_at     = optional(string, "iot_received_at")
    expires_at      = optional(string, "expires_at")
  })
  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for name in [var.telemetry_attributes.node_id, var.telemetry_attributes.reading_at, var.telemetry_attributes.received_at, var.telemetry_attributes.expires_at] : can(regex("^[A-Za-z_][A-Za-z0-9_]{0,63}$", name))])
    error_message = "Attribute names must start with a letter or underscore and use only letters, digits and underscores, at most 64 characters."
  }

  validation {
    condition     = length(distinct([var.telemetry_attributes.node_id, var.telemetry_attributes.reading_at, var.telemetry_attributes.received_at, var.telemetry_attributes.expires_at])) == 4 && length(setintersection(toset([var.telemetry_attributes.node_id, var.telemetry_attributes.reading_at, var.telemetry_attributes.received_at, var.telemetry_attributes.expires_at]), toset(["certificate_principal", "client_id", "source_ip"]))) == 0
    error_message = "The four attribute names must be distinct and must not reuse certificate_principal, client_id or source_ip."
  }

  validation {
    condition     = contains(["S", "N"], var.telemetry_attributes.reading_at_type)
    error_message = "reading_at_type must be S or N."
  }
}

variable "threshold_queue_url" {
  description = "URL of the threshold function queue, from the queue_urls output of the inference-functions module. The topic rule sends each reading there in place of a direct function invocation (ASM-161)."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^https://sqs\\.[a-z0-9-]+\\.amazonaws\\.com/[0-9]{12}/[A-Za-z0-9_-]{1,80}$", var.threshold_queue_url))
    error_message = "The threshold queue must be given by its SQS queue URL."
  }
}

variable "tls_security_policy" {
  description = "Predefined AWS IoT Core security policy of the domain configuration (CL-TEL-01, PD-100). Only policies whose minimum TLS version is 1.2 or later are accepted."
  type        = string
  nullable    = false

  validation {
    condition     = contains(["IoTSecurityPolicy_TLS13_1_2_2022_10", "IoTSecurityPolicy_TLS12_1_2_2022_10", "IoTSecurityPolicy_TLS13_1_3_2022_10"], var.tls_security_policy)
    error_message = "The security policy must be IoTSecurityPolicy_TLS13_1_2_2022_10, IoTSecurityPolicy_TLS12_1_2_2022_10 or IoTSecurityPolicy_TLS13_1_3_2022_10 (minimum TLS 1.2 or later)."
  }
}

variable "topic_namespace" {
  description = "Topic levels above the thing name. A node publishes only to <topic_namespace>/<thing name>. One to six levels of letters, digits, underscores and hyphens, no wildcard and no leading slash."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[A-Za-z0-9_-]+(/[A-Za-z0-9_-]+){0,5}$", var.topic_namespace))
    error_message = "The topic namespace must be one to six slash-separated levels of letters, digits, underscores and hyphens."
  }
}
