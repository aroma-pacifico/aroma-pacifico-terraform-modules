# Synthetic fixtures. client and project are placeholders and every ARN uses the all-zero fixture
# account, so no real account, hostname or principal appears in this public repository.
client       = "fx"
project      = "cf"
environment  = "qa"
resource_key = "state"
region       = "us-east-1"
account_id   = "000000000000"
owner        = "SR1"
cost_center  = "shared"

key_administrators    = ["arn:aws:iam::000000000000:role/fixture-state-apply"]
configuration_readers = ["arn:aws:iam::000000000000:role/fixture-auditor"]

break_glass_role_arn_patterns = ["arn:aws:iam::000000000000:role/aws-reserved/sso.amazonaws.com/*/AWSReservedSSO_FixtureBreakGlass_*"]

domain_access = {
  network = {
    plan_role_arns  = ["arn:aws:iam::000000000000:role/fixture-network-plan"]
    write_role_arns = ["arn:aws:iam::000000000000:role/fixture-network-apply"]
  }
  security = {
    plan_role_arns  = ["arn:aws:iam::000000000000:role/fixture-security-plan"]
    write_role_arns = ["arn:aws:iam::000000000000:role/fixture-security-apply"]
  }
  workload = {
    plan_role_arns  = ["arn:aws:iam::000000000000:role/fixture-workload-plan"]
    write_role_arns = ["arn:aws:iam::000000000000:role/fixture-workload-apply"]
  }
  state-backend = {
    plan_role_arns  = ["arn:aws:iam::000000000000:role/fixture-state-backend-plan"]
    write_role_arns = ["arn:aws:iam::000000000000:role/fixture-state-apply"]
  }
}
