# One invocation of the telemetry ingestion module; all ingestion logic stays inside the reusable module.
module "telemetry_ingestion" {
  source = "../"

  providers = { aws.project = aws.principal }

  client          = var.client
  project         = var.project
  environment     = var.environment
  name_prefix     = local.name_prefix
  additional_tags = local.common_tags

  kms_key_arns        = var.kms_key_arns
  rule_role_arn       = var.rule_role_arn
  logging_role_arn    = var.logging_role_arn
  threshold_queue_url = var.threshold_queue_url

  topic_namespace     = var.topic_namespace
  tls_security_policy = var.tls_security_policy
  retention_days      = var.retention_days
  log_retention_days  = var.log_retention_days
}
