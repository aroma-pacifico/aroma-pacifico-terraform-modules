locals {
  bucket_arn = "arn:${var.aws_context.partition}:s3:::${var.name_prefix}"
  dns_suffix = var.aws_context.partition == "aws-cn" ? "amazonaws.com.cn" : "amazonaws.com"
  tags       = merge(var.additional_tags, { Name = var.name_prefix })
  domain_objects = {
    for domain, access in var.domain_access : domain => {
      state   = "${local.bucket_arn}/${domain}/terraform.tfstate"
      lock    = "${local.bucket_arn}/${domain}/terraform.tfstate.tflock"
      readers = sort(tolist(setunion(access.plan_role_arns, access.write_role_arns)))
      writers = sort(tolist(access.write_role_arns))
    }
  }
  data_roles    = sort(distinct(flatten([for objects in local.domain_objects : objects.readers])))
  trusted_roles = sort(tolist(setunion(var.key_administrators, var.configuration_readers, toset(local.data_roles))))
  # Resource="*" in a KMS key policy means this key only, not all account keys.
  key_policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      {
        Sid       = "ExplicitKeyAdministration"
        Effect    = "Allow"
        Principal = { AWS = sort(tolist(var.key_administrators)) }
        Action = [
          "kms:DescribeKey", "kms:GetKeyPolicy", "kms:PutKeyPolicy",
          "kms:EnableKeyRotation", "kms:GetKeyRotationStatus",
          "kms:UpdateKeyDescription", "kms:TagResource", "kms:UntagResource", "kms:ListResourceTags",
          "kms:CreateAlias", "kms:UpdateAlias", "kms:DeleteAlias"
        ]
        Resource = "*"
      },
      {
        Sid       = "ReadKeyConfiguration"
        Effect    = "Allow"
        Principal = { AWS = sort(tolist(var.configuration_readers)) }
        Action    = ["kms:DescribeKey", "kms:GetKeyPolicy", "kms:GetKeyRotationStatus", "kms:ListResourceTags"]
        Resource  = "*"
      }
      ], [for domain, objects in local.domain_objects : {
        Sid       = "Domain${replace(domain, "-", "")}S3Only"
        Effect    = "Allow"
        Principal = { AWS = objects.readers }
        Action    = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey"]
        Resource  = "*"
        Condition = {
          StringEquals = {
            "kms:CallerAccount"                = var.aws_context.account_id
            "kms:ViaService"                   = "s3.${var.aws_context.region}.${local.dns_suffix}"
            "kms:EncryptionContext:aws:s3:arn" = [objects.state, objects.lock]
          }
        }
    }])
  })
  # Wildcard principals/actions below occur only in explicit Deny statements.
  bucket_policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      {
        Sid       = "DenyNonTLS", Effect = "Deny", Principal = "*", Action = "s3:*"
        Resource  = [local.bucket_arn, "${local.bucket_arn}/*"]
        Condition = { Bool = { "aws:SecureTransport" = "false" } }
      },
      {
        Sid       = "DenyUntrustedPrincipals", Effect = "Deny", Principal = "*", Action = "s3:*"
        Resource  = [local.bucket_arn, "${local.bucket_arn}/*"]
        Condition = { ArnNotEquals = { "aws:PrincipalArn" = local.trusted_roles } }
      },
      {
        Sid      = "DenyWrongEncryption", Effect = "Deny", Principal = "*", Action = "s3:PutObject"
        Resource = "${local.bucket_arn}/*"
        Condition = {
          Null            = { "s3:x-amz-server-side-encryption" = "false" }
          StringNotEquals = { "s3:x-amz-server-side-encryption" = "aws:kms" }
        }
      },
      {
        Sid      = "DenyWrongKey", Effect = "Deny", Principal = "*", Action = "s3:PutObject"
        Resource = "${local.bucket_arn}/*"
        Condition = {
          Null            = { "s3:x-amz-server-side-encryption-aws-kms-key-id" = "false" }
          StringNotEquals = { "s3:x-amz-server-side-encryption-aws-kms-key-id" = aws_kms_key.state.arn }
        }
      },
      {
        Sid      = "DenyKMSWithoutKey", Effect = "Deny", Principal = "*", Action = "s3:PutObject"
        Resource = "${local.bucket_arn}/*"
        Condition = {
          StringEquals = { "s3:x-amz-server-side-encryption" = "aws:kms" }
          Null         = { "s3:x-amz-server-side-encryption-aws-kms-key-id" = "true" }
        }
      },
      {
        Sid      = "DenyStateDeletion", Effect = "Deny", Principal = "*"
        Action   = ["s3:DeleteObject", "s3:DeleteObjectVersion"]
        Resource = [for objects in local.domain_objects : objects.state]
      }
      ], flatten([for domain, objects in local.domain_objects : concat([
        {
          Sid       = "Read${replace(domain, "-", "")}", Effect = "Allow"
          Principal = { AWS = objects.readers }, Action = "s3:GetObject", Resource = objects.state
        },
        {
          Sid       = "List${replace(domain, "-", "")}", Effect = "Allow"
          Principal = { AWS = objects.readers }, Action = "s3:ListBucket", Resource = local.bucket_arn
          Condition = { StringEquals = { "s3:prefix" = ["${domain}/", "${domain}/terraform.tfstate", "${domain}/terraform.tfstate.tflock"] } }
        },
        {
          Sid       = "Lock${replace(domain, "-", "")}", Effect = "Allow"
          Principal = { AWS = objects.readers }
          Action    = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"], Resource = objects.lock
        },
        {
          Sid       = "DenyOtherReaders${replace(domain, "-", "")}", Effect = "Deny", Principal = "*"
          Action    = ["s3:GetObject", "s3:GetObjectVersion"], Resource = objects.state
          Condition = { ArnNotEquals = { "aws:PrincipalArn" = objects.readers } }
        },
        {
          Sid       = "DenyOtherLockUsers${replace(domain, "-", "")}", Effect = "Deny", Principal = "*"
          Action    = ["s3:GetObject", "s3:GetObjectVersion", "s3:PutObject", "s3:DeleteObject", "s3:DeleteObjectVersion"], Resource = objects.lock
          Condition = { ArnNotEquals = { "aws:PrincipalArn" = objects.readers } }
        }
        ], jsondecode(length(objects.writers) == 0 ? jsonencode([
          {
            Sid    = "DenyAllStateWrites${replace(domain, "-", "")}", Effect = "Deny", Principal = "*"
            Action = "s3:PutObject", Resource = objects.state
          }
          ]) : jsonencode([
          {
            Sid       = "Write${replace(domain, "-", "")}", Effect = "Allow"
            Principal = { AWS = objects.writers }, Action = "s3:PutObject", Resource = objects.state
          },
          {
            Sid       = "DenyOtherWriters${replace(domain, "-", "")}", Effect = "Deny", Principal = "*"
            Action    = "s3:PutObject", Resource = objects.state
            Condition = { ArnNotEquals = { "aws:PrincipalArn" = objects.writers } }
          }
    ])))]))
  })
}
