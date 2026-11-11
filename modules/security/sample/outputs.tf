output "kms_key_arns" {
  description = "ARN of each customer-managed key, keyed by data class."
  value       = module.security.kms_key_arns
}

output "mfa_required_roles" {
  description = "Roles whose pool requires a TOTP second factor."
  value       = module.security.mfa_required_roles
}

output "revocation_role_arn" {
  description = "ARN of the role of the revocation function."
  value       = module.security.revocation_role_arn
}

output "staff_user_pool_id" {
  description = "ID of the staff user pool."
  value       = module.security.staff_user_pool_id
}
