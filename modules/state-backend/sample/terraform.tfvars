# Deliberately incomplete, non-operational example. Native tests inject computed synthetic identities.
configuration = {
  client             = "fx", project = "cf", environment = "qa", resource_key = "state"
  aws_context        = { account_id = "", partition = "aws", region = "us-east-1" }
  execution_role_arn = ""
  owner              = "REQUIRED_OWNER", cost_center = "REQUIRED_COST_CENTER"
  key_administrators = [], configuration_readers = [], domain_access = {}
}
