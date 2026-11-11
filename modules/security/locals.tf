locals {
  # PC-IAC-003 caps a physical name at 28 characters. The longest suffix this module appends is
  # 12 characters ("-public-view" for a key alias), which leaves 16 for the prefix.
  max_name_prefix_length = 16

  governance_tags = merge({
    Client      = var.client
    Project     = var.project
    Environment = var.environment
  }, var.additional_tags)

  partition  = data.aws_partition.current.partition
  region     = data.aws_region.current.region
  account_id = data.aws_caller_identity.current.account_id

  # One customer-managed key per data class and environment (security-and-identity section 7.2, ASM-097).
  key_classes = toset(["telemetry", "objects", "records", "personal", "logs", "state", "public_view", "restricted"])

  # Role catalog (security-and-identity section 4.1). The anonymous public reader has no identity.
  # MFA follows the pool: the staff pool requires it, so the three roles of the case statement
  # (collection_center_operator, drone_operator, platform_operator) and the agronomist of ADR-002 have it.
  roles = {
    farmer                     = { pool = "field" }
    transporter                = { pool = "field" }
    buyer                      = { pool = "field" }
    collection_center_operator = { pool = "staff" }
    drone_operator             = { pool = "staff" }
    agronomist                 = { pool = "staff" }
    platform_operator          = { pool = "staff" }
  }

  mfa_required_roles = sort([for role, definition in local.roles : role if definition.pool == "staff"])

  pool_arns = [aws_cognito_user_pool.staff.arn, aws_cognito_user_pool.field.arn]

  # Field pool sign-in factors: email always, SMS only when the root supplies the SNS role (ASM-090, ASM-091).
  field_first_auth_factors = nonsensitive(var.field_sms_configuration == null) ? ["EMAIL_OTP"] : ["SMS_OTP", "EMAIL_OTP"]

  # Only the log service of this account and Region may use the logs key for log groups.
  logs_service_principal = "logs.${local.region}.amazonaws.com"
  logs_encryption_arn    = "arn:${local.partition}:logs:${local.region}:${local.account_id}:*"

  protected_bucket_resources = flatten([for bucket_arn in var.protected_bucket_arns : [bucket_arn, "${bucket_arn}/*"]])
}
