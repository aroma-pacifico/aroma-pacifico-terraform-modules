output "state_bucket_name" {
  description = "Environment state bucket name for partial S3 backend configuration."
  value       = aws_s3_bucket.state.bucket
}

output "state_bucket_arn" {
  description = "State bucket reference for scoped IAM integration."
  value       = local.bucket_arn
}

output "state_kms_key_arn" {
  description = "Environment state CMK reference; never key material."
  value       = aws_kms_key.state.arn
}

output "state_kms_key_id" {
  description = "Environment state CMK identifier; never key material."
  value       = aws_kms_key.state.key_id
}

output "backend_region" {
  description = "Root-verified Region for backend configuration."
  value       = var.aws_context.region
}
