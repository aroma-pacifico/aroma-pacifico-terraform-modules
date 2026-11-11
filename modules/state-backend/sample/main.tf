# Offline development composition; never use a local source in a shared environment.
module "state_backend" {
  source    = "../"
  providers = { aws.project = aws.principal }

  client      = local.configuration.client
  project     = local.configuration.project
  environment = local.configuration.environment

  name_prefix     = local.name_prefix
  additional_tags = local.common_tags

  aws_context           = local.configuration.aws_context
  key_administrators    = local.configuration.key_administrators
  configuration_readers = local.configuration.configuration_readers
  domain_access         = local.configuration.domain_access
}
