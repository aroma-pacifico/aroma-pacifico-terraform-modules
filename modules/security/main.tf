# Customer-managed keys, one per data class (security-and-identity section 7.2 and 7.3).
data "aws_iam_policy_document" "key" {
  #checkov:skip=CKV_AWS_109:In a KMS key policy the resource "*" means the key the policy is attached to.
  #checkov:skip=CKV_AWS_111:Same: the key policy cannot name its own key, and the principals are explicit ARNs.
  #checkov:skip=CKV_AWS_356:Same: the resource "*" is the key itself.
  for_each = local.key_classes

  provider = aws.project

  # Administrators manage the key but cannot use it to read data.
  statement {
    sid       = "AdministerKey"
    effect    = "Allow"
    actions   = ["kms:Create*", "kms:Describe*", "kms:Enable*", "kms:List*", "kms:Put*", "kms:Update*", "kms:Revoke*", "kms:Get*", "kms:TagResource", "kms:UntagResource", "kms:ScheduleKeyDeletion", "kms:CancelKeyDeletion"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = var.key_administrator_arns
    }
  }

  # Only the named service roles of this environment use the key.
  dynamic "statement" {
    for_each = length(lookup(var.key_user_arns, each.key, [])) > 0 ? [1] : []

    content {
      sid       = "UseKey"
      effect    = "Allow"
      actions   = ["kms:Decrypt", "kms:DescribeKey", "kms:Encrypt", "kms:GenerateDataKey*", "kms:ReEncrypt*"]
      resources = ["*"]

      principals {
        type        = "AWS"
        identifiers = var.key_user_arns[each.key]
      }
    }
  }

  # CloudWatch Logs cannot use the logs key through a role, so the service principal is named, limited to this account.
  dynamic "statement" {
    for_each = each.key == "logs" ? [1] : []

    content {
      sid       = "AllowLogsService"
      effect    = "Allow"
      actions   = ["kms:Decrypt", "kms:DescribeKey", "kms:Encrypt", "kms:GenerateDataKey*", "kms:ReEncrypt*"]
      resources = ["*"]

      principals {
        type        = "Service"
        identifiers = [local.logs_service_principal]
      }

      condition {
        test     = "ArnLike"
        variable = "kms:EncryptionContext:aws:logs:arn"
        values   = [local.logs_encryption_arn]
      }
    }
  }

  # Deletion and disabling stay with break glass, whatever any other statement or IAM policy grants.
  statement {
    sid       = "DenyDeletionExceptBreakGlass"
    effect    = "Deny"
    actions   = ["kms:ScheduleKeyDeletion", "kms:DisableKey"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "ArnNotLike"
      variable = "aws:PrincipalArn"
      values   = var.break_glass_role_arn_patterns
    }
  }
}

resource "aws_kms_key" "this" {
  for_each = local.key_classes

  provider = aws.project

  description              = "Customer-managed key for the ${each.key} data class."
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  deletion_window_in_days  = 30
  enable_key_rotation      = true
  is_enabled               = true
  key_usage                = "ENCRYPT_DECRYPT"
  policy                   = data.aws_iam_policy_document.key[each.key].json
  rotation_period_in_days  = 365

  tags = merge(local.governance_tags, { Name = "${var.name_prefix}-${replace(each.key, "_", "-")}" })
}

resource "aws_kms_alias" "this" {
  for_each = local.key_classes

  provider = aws.project

  name          = "alias/${var.name_prefix}-${replace(each.key, "_", "-")}"
  target_key_id = aws_kms_key.this[each.key].key_id
}

# Application identity directory (security-and-identity section 3). MFA is a setting of the whole pool,
# so two pools make the split of the case statement a configuration, not an application check.
resource "aws_cognito_user_pool" "staff" {
  provider = aws.project

  deletion_protection      = "ACTIVE"
  mfa_configuration        = "ON"
  name                     = "${var.name_prefix}-pool-staff"
  user_pool_tier           = "ESSENTIALS"
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  password_policy {
    minimum_length                   = 14
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 3
  }

  # TOTP only: SMS is not offered as a second factor because a SIM swap can take it over (section 5.1).
  software_token_mfa_configuration {
    enabled = true
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  tags = merge(local.governance_tags, { Name = "${var.name_prefix}-pool-staff" })
}

resource "aws_cognito_user_pool" "field" {
  provider = aws.project

  deletion_protection = "ACTIVE"
  mfa_configuration   = "OFF"
  name                = "${var.name_prefix}-pool-field"
  user_pool_tier      = "ESSENTIALS"

  # Farmers and transporters sign in by passwordless one-time code and have no MFA, as a justified decision (ASM-091).
  sign_in_policy {
    allowed_first_auth_factors = local.field_first_auth_factors
  }

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  dynamic "sms_configuration" {
    for_each = var.field_sms_configuration == null ? [] : [var.field_sms_configuration]

    content {
      external_id    = sms_configuration.value.external_id
      sns_caller_arn = sms_configuration.value.sns_caller_arn
    }
  }

  tags = merge(local.governance_tags, { Name = "${var.name_prefix}-pool-field" })
}

# One group per role (security-and-identity section 3.2).
resource "aws_cognito_user_group" "this" {
  for_each = local.roles

  provider = aws.project

  description  = "Role ${each.key}; least privilege is enforced by the application API."
  name         = each.key
  user_pool_id = each.value.pool == "staff" ? aws_cognito_user_pool.staff.id : aws_cognito_user_pool.field.id
}

# Revocation of a farm node, a lost drone or a user (security-and-identity section 10). The role is assumed by
# the revocation function; it holds only the actions that stop a device publishing and end a user session.
data "aws_iam_policy_document" "revocation_trust" {
  provider = aws.project

  statement {
    sid     = "AssumeByRevocationFunction"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "revocation" {
  provider = aws.project

  statement {
    sid       = "RevokeDeviceCertificate"
    effect    = "Allow"
    actions   = ["iot:UpdateCertificate", "iot:DetachPolicy", "iot:DescribeCertificate", "iot:ListAttachedPolicies", "iot:ListCertificates"]
    resources = ["arn:${local.partition}:iot:${local.region}:${local.account_id}:cert/*"]
  }

  statement {
    sid       = "DetachAndMarkThing"
    effect    = "Allow"
    actions   = ["iot:DetachThingPrincipal", "iot:UpdateThing", "iot:DescribeThing", "iot:ListThingPrincipals"]
    resources = ["arn:${local.partition}:iot:${local.region}:${local.account_id}:thing/*"]
  }

  statement {
    sid       = "EndUserSessions"
    effect    = "Allow"
    actions   = ["cognito-idp:AdminAddUserToGroup", "cognito-idp:AdminDisableUser", "cognito-idp:AdminEnableUser", "cognito-idp:AdminGetUser", "cognito-idp:AdminRemoveUserFromGroup", "cognito-idp:AdminSetUserMFAPreference", "cognito-idp:AdminUserGlobalSignOut"]
    resources = local.pool_arns
  }
}

resource "aws_iam_role" "revocation" {
  provider = aws.project

  assume_role_policy   = data.aws_iam_policy_document.revocation_trust.json
  description          = "Revokes device certificates and ends user sessions; assumed by the revocation function."
  max_session_duration = 3600
  name                 = "${var.name_prefix}-role-revoke"

  tags = merge(local.governance_tags, { Name = "${var.name_prefix}-role-revoke" })
}

resource "aws_iam_role_policy" "revocation" {
  provider = aws.project

  name   = "revocation"
  policy = data.aws_iam_policy_document.revocation.json
  role   = aws_iam_role.revocation.id
}

# Encryption in transit: bucket policy statements that the owner of each bucket attaches (section 7.1).
data "aws_iam_policy_document" "secure_transport" {
  count = length(var.protected_bucket_arns) > 0 ? 1 : 0

  provider = aws.project

  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = local.protected_bucket_resources

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid       = "DenyOldTlsVersion"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = local.protected_bucket_resources

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values   = ["1.2"]
    }
  }
}
