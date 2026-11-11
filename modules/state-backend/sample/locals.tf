locals {
  name_prefix = "${var.configuration.client}-${var.configuration.project}-${var.configuration.environment}-${var.configuration.resource_key}"
  common_tags = {
    Client      = var.configuration.client, Project = var.configuration.project,
    Environment = var.configuration.environment, Owner = var.configuration.owner,
    CostCenter  = var.configuration.cost_center
  }
  configuration = var.configuration
  backend_configuration = {
    for domain in keys(var.configuration.domain_access) : domain => {
      bucket              = module.state_backend.state_bucket_name
      key                 = "${domain}/terraform.tfstate"
      region              = module.state_backend.backend_region
      encrypt             = true
      use_lockfile        = true
      kms_key_id          = module.state_backend.state_kms_key_arn
      allowed_account_ids = [var.configuration.aws_context.account_id]
    }
  }
}
