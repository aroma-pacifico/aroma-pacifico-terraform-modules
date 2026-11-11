# Logical cloud registry identities, not physical hardware or firmware deployment.
resource "aws_iot_thing" "node" {
  for_each = var.nodes

  provider = aws.project
  name     = local.node_names[each.key]
  attributes = {
    FarmId = var.farm_id, Environment = var.environment, NodeRole = each.key
  }
}

resource "aws_iot_certificate" "node" {
  for_each = var.nodes

  provider = aws.project
  active   = true
  csr      = each.value.csr
}

resource "aws_iot_thing_principal_attachment" "node" {
  for_each = var.nodes

  provider  = aws.project
  principal = aws_iot_certificate.node[each.key].arn
  thing     = aws_iot_thing.node[each.key].name
}

resource "aws_iot_policy_attachment" "node" {
  for_each = var.nodes

  provider = aws.project
  policy   = var.ingestion.policy_name
  target   = aws_iot_certificate.node[each.key].arn
}
