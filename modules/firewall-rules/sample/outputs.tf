output "prefix_list_ids" {
  description = "IDs of the five collection center prefix lists."
  value       = module.firewall_rules.prefix_list_ids
}

output "rule_catalog" {
  description = "Rules created by the module, with validity and audit flag."
  value       = module.firewall_rules.rule_catalog
}

output "security_group_ids" {
  description = "Security group IDs created by the module."
  value       = module.firewall_rules.security_group_ids
}

output "web_acl_arns" {
  description = "ARNs of the lookup and API web ACLs."
  value       = module.firewall_rules.web_acl_arns
}
