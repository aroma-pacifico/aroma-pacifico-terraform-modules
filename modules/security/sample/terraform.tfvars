# Synthetic fixtures. client and project are placeholders and every ARN uses the all-zero fixture
# account, so no real account, hostname or principal appears in this public repository.
client      = "fx"
project     = "cf"
environment = "pdn"
region      = "us-east-1"

key_administrator_arns        = ["arn:aws:iam::000000000000:role/fixture-security-apply"]
break_glass_role_arn_patterns = ["arn:aws:iam::000000000000:role/aws-reserved/sso.amazonaws.com/*/AWSReservedSSO_FixtureBreakGlass_*"]

key_user_arns = {
  telemetry = ["arn:aws:iam::000000000000:role/fixture-threshold-function"]
  records   = ["arn:aws:iam::000000000000:role/fixture-threshold-function"]
  objects   = ["arn:aws:iam::000000000000:role/fixture-inference-function"]
}

protected_bucket_arns = ["arn:aws:s3:::fixture-drone-objects"]
