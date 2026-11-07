locals {
  governance_prefix = "${var.client}-${var.project}-${var.environment}"
  name_prefix       = "${local.governance_prefix}-iot-${var.farm_key}"
  common_tags = {
    Client = var.client, Project = var.project, Environment = var.environment,
    Owner  = "JR2", CostCenter = "farms", FarmId = var.farm_id
  }
  nodes     = { for role, csr_path in var.node_csr_paths : role => { csr = file("${path.module}/${csr_path}") } }
  ingestion = var.ingestion
}
