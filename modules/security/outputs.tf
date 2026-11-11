output "cognito_group_names" {
  description = "Cognito group name of each role, keyed by role."
  value       = { for role, group in aws_cognito_user_group.this : role => group.name }
}

output "field_user_pool_arn" {
  description = "ARN of the field user pool (farmer, transporter, buyer; no MFA)."
  value       = aws_cognito_user_pool.field.arn
}

output "field_user_pool_id" {
  description = "ID of the field user pool."
  value       = aws_cognito_user_pool.field.id
}

output "iot_logging_role_arn" {
  description = "ARN of the role that AWS IoT Core assumes to write its logs; the logging_role_arn input of the telemetry-ingestion module."
  value       = aws_iam_role.iot_logging.arn
}

output "iot_rule_role_arn" {
  description = "ARN of the role that the telemetry topic rule assumes; the rule_role_arn input of the telemetry-ingestion module."
  value       = aws_iam_role.iot_rule.arn
}

output "kms_key_alias_names" {
  description = "Alias name of each key, keyed by data class."
  value       = { for class, alias in aws_kms_alias.this : class => alias.name }
}

output "kms_key_arns" {
  description = "ARN of each customer-managed key, keyed by data class (telemetry, objects, records, personal, logs, state, public_view, restricted)."
  value       = { for class, key in aws_kms_key.this : class => key.arn }
}

output "kms_key_ids" {
  description = "ID of each customer-managed key, keyed by data class."
  value       = { for class, key in aws_kms_key.this : class => key.key_id }
}

output "mfa_required_roles" {
  description = "Roles whose pool requires a TOTP second factor: the three of the case statement plus the agronomist (ADR-002)."
  value       = local.mfa_required_roles
}

output "revocation_role_arn" {
  description = "ARN of the role of the revocation function."
  value       = aws_iam_role.revocation.arn
}

output "revocation_role_name" {
  description = "Name of the revocation role, for attaching the basic execution policy of the function."
  value       = aws_iam_role.revocation.name
}

output "secure_transport_policy_statements_json" {
  description = "Bucket policy with the two deny statements for plain HTTP and TLS below 1.2, or null when no bucket is protected. Merge it into the policy of each protected bucket."
  value       = one(data.aws_iam_policy_document.secure_transport[*].json)
}

output "staff_user_pool_arn" {
  description = "ARN of the staff user pool (collection-center operator, drone operator, agronomist, platform operator; MFA required)."
  value       = aws_cognito_user_pool.staff.arn
}

output "staff_user_pool_id" {
  description = "ID of the staff user pool."
  value       = aws_cognito_user_pool.staff.id
}
