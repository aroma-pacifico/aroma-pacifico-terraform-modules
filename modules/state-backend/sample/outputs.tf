output "backend_configuration" {
  description = "Non-secret future S3 configuration for four domains; output does not initialize any backend."
  value       = local.backend_configuration
}
