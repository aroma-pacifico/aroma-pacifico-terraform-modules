resource "aws_kms_key" "state" {
  provider                           = aws.project
  description                        = "Remote Terraform state and lock encryption for ${var.name_prefix}"
  deletion_window_in_days            = 30
  enable_key_rotation                = true
  rotation_period_in_days            = 365
  bypass_policy_lockout_safety_check = false
  policy                             = local.key_policy
  tags                               = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_kms_alias" "state" {
  provider      = aws.project
  name          = "alias/${var.name_prefix}"
  target_key_id = aws_kms_key.state.key_id
}

resource "aws_s3_bucket" "state" {
  provider      = aws.project
  bucket        = var.name_prefix
  force_destroy = false
  tags          = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_ownership_controls" "state" {
  provider = aws.project
  bucket   = aws_s3_bucket.state.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  provider                = aws.project
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "state" {
  provider              = aws.project
  bucket                = aws_s3_bucket.state.id
  expected_bucket_owner = var.aws_context.account_id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  provider              = aws.project
  bucket                = aws_s3_bucket.state.id
  expected_bucket_owner = var.aws_context.account_id
  rule {
    # Object ARN encryption context is required by the domain-scoped KMS policy.
    bucket_key_enabled = false
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.state.arn
    }
  }
}

resource "aws_s3_bucket_policy" "state" {
  provider = aws.project
  bucket   = aws_s3_bucket.state.id
  policy   = local.bucket_policy

  # Apply access only after security subresources exist; these are hidden API dependencies.
  depends_on = [aws_s3_bucket_ownership_controls.state, aws_s3_bucket_public_access_block.state, aws_s3_bucket_versioning.state, aws_s3_bucket_server_side_encryption_configuration.state]
}
