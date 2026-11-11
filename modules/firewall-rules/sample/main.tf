# One invocation of the firewall rules module; all rule logic stays inside the reusable module.
module "firewall_rules" {
  source = "../"

  providers = { aws.project = aws.principal }

  client                        = var.client
  project                       = var.project
  environment                   = var.environment
  name_prefix                   = local.name_prefix
  additional_tags               = local.common_tags
  vpc_id                        = var.vpc_id
  waf_scope                     = var.waf_scope
  collection_centers            = var.collection_centers
  application_cidr_blocks       = var.application_cidr_blocks
  data_store_ports              = var.data_store_ports
  enable_cloudfront_origin_rule = var.enable_cloudfront_origin_rule
  api_endpoint                  = var.api_endpoint
  drone_object_endpoint         = var.drone_object_endpoint
  lookup_allowed_path_prefixes  = var.lookup_allowed_path_prefixes
  lookup_rate_scope_path        = var.lookup_rate_scope_path
  lookup_rate_limit             = var.lookup_rate_limit
  api_rate_limit                = var.api_rate_limit
  temporary_rules               = var.temporary_rules
}
