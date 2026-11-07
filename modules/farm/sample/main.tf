module "farm" {
  source = "../"

  providers = { aws.project = aws.principal }

  client      = var.client
  project     = var.project
  environment = var.environment

  name_prefix     = local.name_prefix
  additional_tags = local.common_tags

  farm_id   = var.farm_id
  nodes     = local.nodes
  ingestion = local.ingestion
}
