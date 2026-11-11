# One invocation of the network module; all network logic stays inside the reusable module.
module "network" {
  source = "../"

  providers = { aws.project = aws.principal }

  client                                       = var.client
  project                                      = var.project
  environment                                  = var.environment
  name_prefix                                  = local.name_prefix
  additional_tags                              = local.common_tags
  vpc_cidr_block                               = var.vpc_cidr_block
  subnets                                      = var.subnets
  collection_center_cidr_blocks                = var.collection_center_cidr_blocks
  collection_center_summary_cidr_block         = var.collection_center_summary_cidr_block
  collection_center_firewall_cidr_blocks       = var.collection_center_firewall_cidr_blocks
  collection_center_ground_station_cidr_blocks = var.collection_center_ground_station_cidr_blocks
  data_store_ports                             = var.data_store_ports
  transit_gateway_id                           = var.transit_gateway_id
}
