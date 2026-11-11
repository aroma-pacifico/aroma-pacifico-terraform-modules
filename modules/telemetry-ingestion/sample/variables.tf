variable "client" {
  description = "Synthetic client value."
  type        = string
}

variable "environment" {
  description = "Environment code: dev, qa or pdn."
  type        = string
}

variable "kms_key_arns" {
  description = "Fixture key ARNs by data class, in the shape of the kms_key_arns output of the security module."
  type        = map(string)
}

variable "log_retention_days" {
  description = "Retention of the IoT Core log group in days."
  type        = number
}

variable "logging_role_arn" {
  description = "Fixture ARN of the IoT Core logging role created by the security stack."
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

variable "retention_days" {
  description = "Days a stored reading is kept. The sample uses the 5 years of the case statement as 1826 days."
  type        = number
}

variable "rule_role_arn" {
  description = "Fixture ARN of the topic rule role created by the security stack."
  type        = string
}

variable "threshold_queue_url" {
  description = "Fixture URL of the threshold queue, as the inference-functions module outputs it."
  type        = string
}

variable "tls_security_policy" {
  description = "Predefined IoT Core security policy with a TLS 1.2 minimum."
  type        = string
}

variable "topic_namespace" {
  description = "Topic levels above the thing name."
  type        = string
}
