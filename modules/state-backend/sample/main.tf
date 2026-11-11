# Offline development composition; a shared environment consumes the module by git tag.
module "state_backend" {
  source = "../"

  providers = { aws.project = aws.principal }

  client      = var.client
  project     = var.project
  environment = var.environment

  name_prefix     = local.name_prefix
  additional_tags = local.common_tags

  aws_context                   = local.aws_context
  key_administrators            = var.key_administrators
  configuration_readers         = var.configuration_readers
  break_glass_role_arn_patterns = var.break_glass_role_arn_patterns
  domain_access                 = var.domain_access
}
