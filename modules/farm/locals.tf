locals {
  # Two node roles within one farm, never a collection of pilot farms.
  node_names = { for role, node in var.nodes : role => "${var.name_prefix}-${role}" }
  telemetry_topics = {
    for role, name in local.node_names : role => replace(var.ingestion.topic_template, "{thing_name}", name)
  }
  desired_cost_tags = merge(var.additional_tags, {
    Client = var.client, Project = var.project, Environment = var.environment,
    FarmId = var.farm_id, CostCenter = "farms"
  })
}
