locals {
  tags = merge(var.additional_tags, { Client = var.client, Project = var.project, Environment = var.environment, CollectionCenter = var.center.key })
}
