variable "name_prefix" {
  description = "Optional prefix for resource names"
  type        = string
  default     = ""
}

variable "s3_bucket_name" {
  description = "S3 bucket name for function code"
  type        = string
}

variable "lambda_source_path" {
  description = "Local path to zipped Lambda source files"
  type        = string
  default     = "lambda"
}

variable "functions" {
  description = "Map of function identifiers to description (used for naming)"
  type = map(object({
    description = string
  }))
  default = {
    confirmation = { description = "Confirmation function" }
    verification = { description = "Verification function" }
    estimation   = { description = "Estimation function" }
    telemetry    = { description = "Telemetry threshold function" }
  }
}

// Security module outputs as inputs
variable "kms_key_arns" {
  description = "List of KMS key ARNs from security module"
  type        = list(string)
}

variable "kms_key_ids" {
  description = "List of KMS key IDs"
  type        = list(string)
}

variable "kms_key_alias_names" {
  description = "List of KMS key alias names"
  type        = list(string)
}

variable "cognito_user_pool_id" {
  description = "Cognito user pool ID"
  type        = string
}

variable "cognito_user_pool_client_id" {
  description = "Cognito user pool client ID"
  type        = string
}

variable "revocation_role_arn" {
  description = "IAM role ARN for token revocation"
  type        = string
}
