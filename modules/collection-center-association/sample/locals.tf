locals {
  name_prefix = "fx-cf-${var.network.environment}-cc"
  network     = var.network
  hub         = var.hub
  center      = var.center
  common_tags = { Client = "fx", Project = "cf", Environment = var.network.environment, Owner = "fixture", CostCenter = "collection-centers" }
}
