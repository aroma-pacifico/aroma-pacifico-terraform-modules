# One invocation of the inference functions module; all pattern logic stays inside the module.
module "inference_functions" {
  source = "../"

  providers = { aws.project = aws.principal }

  client             = var.client
  project            = var.project
  environment        = var.environment
  name_prefix        = local.name_prefix
  additional_tags    = local.common_tags
  functions          = local.functions
  kms_key_arns       = var.kms_key_arns
  log_retention_days = 365
}
