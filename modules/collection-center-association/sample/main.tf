# Local verification only; shared environment consumption must use a reviewed release.
module "association" {
  source    = "../"
  providers = { aws.project = aws.principal, aws.network = aws.network }

  client      = "fx"
  project     = "cf"
  environment = var.network.environment

  name_prefix     = local.name_prefix
  additional_tags = local.common_tags

  network = local.network
  hub     = local.hub
  center  = local.center
}
