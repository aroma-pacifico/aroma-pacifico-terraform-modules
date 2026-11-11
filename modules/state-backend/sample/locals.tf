# Roots construct governance names, tags and the backend settings handed to future domain roots.
locals {
  name_prefix = "${var.client}-${var.project}-${var.environment}-${var.resource_key}"

  common_tags = {
    Client      = var.client
    Project     = var.project
    Environment = var.environment
    Owner       = var.owner
    CostCenter  = var.cost_center
  }

  aws_context = {
    account_id = var.account_id
    partition  = "aws"
    region     = var.region
  }

  backend_configuration = {
    for domain in keys(var.domain_access) : domain => {
      bucket              = module.state_backend.state_bucket_name
      key                 = "${domain}/terraform.tfstate"
      region              = module.state_backend.backend_region
      encrypt             = true
      use_lockfile        = true
      kms_key_id          = module.state_backend.state_kms_key_arn
      allowed_account_ids = [var.account_id]
    }
  }
}
