# One invocation of the network module; all network logic stays inside the reusable module.
module "network" {
  source = "../"

  providers = { aws.project = aws.principal }

  client                        = var.client
  project                       = var.project
  environment                   = var.environment
  name_prefix                   = local.name_prefix
  additional_tags               = local.common_tags
  vpc_cidr_block                = var.vpc_cidr_block
  subnets                       = var.subnets
  collection_center_cidr_blocks = var.collection_center_cidr_blocks
}
