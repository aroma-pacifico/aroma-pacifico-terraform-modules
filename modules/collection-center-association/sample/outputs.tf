output "selected_center" {
  description = "Single selected center contract."
  value       = module.association.selected_center
}
output "routing_references" {
  description = "Public B07 integration references; never keys or configuration XML."
  value       = { vpc_attachment_id = module.association.vpc_attachment_id, vpn_attachment_id = module.association.vpn_attachment_id, prefix_list_id = module.association.center_prefix_list_id }
}
