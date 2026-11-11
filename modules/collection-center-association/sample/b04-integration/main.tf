# One invocation of the network module; all network logic stays inside the reusable module.
module "network" {
  source = "../../../network"

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
  organization_id                              = var.organization_id
  interface_endpoints                          = var.interface_endpoints
  flow_logs                                    = var.flow_logs
  data_store_ports                             = var.data_store_ports
  transit_gateway_id                           = var.transit_gateway_id
}

module "association" {
  source    = "../../"
  providers = { aws.project = aws.principal, aws.network = aws.network }

  client      = var.client
  project     = var.project
  environment = var.environment

  name_prefix     = "${local.name_prefix}-cc"
  additional_tags = local.common_tags

  center = { key = "fixture", cidr_block = "10.41.0.0/16" }
  network = {
    environment                   = var.environment
    account_id                    = format("%012d", 0)
    vpc_id                        = module.network.vpc_id
    vpc_cidr_block                = module.network.vpc_cidr_block
    transit_attachment_subnet_ids = module.network.transit_attachment_subnet_ids
  }
  hub = {
    account_id               = format("%012d", 1)
    region                   = var.region
    transit_gateway_id       = var.transit_gateway_id
    customer_certificate_arn = "arn:aws:acm:${var.region}:${format("%012d", 1)}:certificate/00000000-0000-0000-0000-000000000000"
  }
}
