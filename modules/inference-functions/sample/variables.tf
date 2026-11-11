variable "alert_table_arn" {
  description = "Fixture ARN of the alert store written by the telemetry function."
  type        = string
}

variable "alert_topic_arn" {
  description = "Fixture ARN of the alert topic published by the telemetry function."
  type        = string
}

variable "client" {
  description = "Synthetic client value."
  type        = string
}

variable "drone_object_bucket_arn_pattern" {
  description = "Fixture object ARN pattern of the drone object bucket (read only)."
  type        = string
}

variable "environment" {
  description = "Environment code: dev, qa or pdn."
  type        = string
}

variable "event_rule_arn_pattern" {
  description = "Fixture ARN pattern of the EventBridge rules that target the drone function queues."
  type        = string
}

variable "iot_rule_arn" {
  description = "Fixture ARN of the telemetry topic rule that sends to the threshold queue."
  type        = string
}

variable "kms_key_arns" {
  description = "Fixture key ARNs by data class, in the shape of the kms_key_arns output of the security module."
  type        = map(string)
}

variable "mission_table_arn" {
  description = "Fixture ARN of the mission and case table."
  type        = string
}

variable "model_id" {
  description = "Foundation model identifier of ASM-160, a configuration value of each function."
  type        = string
}

variable "project" {
  description = "Synthetic project value."
  type        = string
}

variable "region" {
  description = "Region of the offline provider."
  type        = string
}

variable "telemetry_table_arn" {
  description = "Fixture ARN of the telemetry table (read only)."
  type        = string
}

variable "thresholds_table_arn" {
  description = "Fixture ARN of the thresholds table (read only)."
  type        = string
}
