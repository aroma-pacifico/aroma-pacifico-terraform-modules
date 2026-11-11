mock_provider "aws" {
  alias           = "principal"
  override_during = plan

  mock_resource "aws_ec2_managed_prefix_list" {
    defaults = { id = "pl-0a1a1a1a1a1a1a1a1" }
  }

  mock_resource "aws_security_group" {
    defaults = { id = "sg-0a1a1a1a1a1a1a1a1" }
  }
}

run "sample_plans_the_permanent_rules_without_a_guest_path" {
  command = plan

  assert {
    condition     = length(output.prefix_list_ids) == 5 && length(output.security_group_ids) == 3
    error_message = "The sample must plan five prefix lists and three security groups."
  }

  assert {
    condition     = toset(keys(output.rule_catalog)) == toset(["CL-ADM-01", "CL-ADM-03", "CL-DAT-02", "CL-PUB-01", "CL-TEL-03"]) && alltrue([for rule in values(output.rule_catalog) : rule.validity == "permanent"])
    error_message = "The sample must catalog five permanent rules."
  }

  assert {
    condition     = length(output.web_acl_arns) == 2
    error_message = "The sample must plan the lookup and API web ACLs."
  }
}
