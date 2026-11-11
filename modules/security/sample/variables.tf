variable "break_glass_role_arn_patterns" {
  description = "Synthetic break-glass role ARN patterns."
  type        = list(string)
}

variable "client" {
  description = "Synthetic client value."
  type        = string
}

variable "environment" {
  description = "Environment code: dev, qa or pdn."
  type        = string
}

variable "key_administrator_arns" {
  description = "Synthetic key administrator ARNs."
  type        = list(string)
}

variable "key_user_arns" {
  description = "Synthetic key users keyed by data class."
  type        = map(list(string))
}

variable "project" {
  description = "Synthetic project value."
  type        = string
}

variable "protected_bucket_arns" {
  description = "Synthetic bucket ARNs that must refuse insecure transport."
  type        = set(string)
}

variable "region" {
  description = "AWS Region of the sample provider."
  type        = string
}
