# Roots construct governance names and tags, then pass them to the module.
locals {
  name_prefix = "${var.client}-${var.project}-${var.environment}"

  common_tags = {
    Client      = var.client
    Project     = var.project
    Environment = var.environment
    Owner       = "SR1"
    CostCenter  = "shared"
  }
}
