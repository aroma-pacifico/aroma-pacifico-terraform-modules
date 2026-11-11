output "prefix_list_ids" {
  description = "IDs of the five collection center prefix lists, keyed cc_device_mgmt, cc_firewalls, cc_ground_stations, cc_logistics and cc_staff."
  value       = { for key, prefix_list in aws_ec2_managed_prefix_list.this : key => prefix_list.id }
}

output "rule_catalog" {
  description = "Every rule this module creates, keyed by the ID of the policy table, with its group, mechanism, validity (permanent or temporary) and whether it is audited before production (PD-125)."
  value       = local.rule_catalog
}

output "security_group_ids" {
  description = "Security group IDs keyed session_host, resolver and data_store, plus load_balancer when the CloudFront origin rule is enabled."
  value = merge(
    {
      data_store   = aws_security_group.data_store.id
      resolver     = aws_security_group.resolver.id
      session_host = aws_security_group.session_host.id
    },
    { for security_group in aws_security_group.load_balancer : "load_balancer" => security_group.id }
  )
}

output "temporary_rule_ids" {
  description = "IDs of the temporary security group rules, keyed like the temporary_rules input."
  value       = { for key, rule in aws_vpc_security_group_ingress_rule.temporary : key => rule.id }
}

output "web_acl_arns" {
  description = "ARNs of the web ACLs, keyed lookup and api. The root attaches them to the front doors."
  value = {
    api    = aws_wafv2_web_acl.api.arn
    lookup = aws_wafv2_web_acl.lookup.arn
  }
}
