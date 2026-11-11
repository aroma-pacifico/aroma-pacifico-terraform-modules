# Synthetic values only: this repository is public. The all-zero account is the documented fixture value,
# and the role, key and queue names are placeholders, not real resources.
client      = "fx"
project     = "cf"
environment = "pdn"
region      = "us-east-1"

kms_key_arns = {
  telemetry = "arn:aws:kms:us-east-1:000000000000:key/00000000-0000-0000-0000-000000000001"
  logs      = "arn:aws:kms:us-east-1:000000000000:key/00000000-0000-0000-0000-000000000005"
}

rule_role_arn       = "arn:aws:iam::000000000000:role/fixture-iot-rule"
logging_role_arn    = "arn:aws:iam::000000000000:role/fixture-iot-logging"
threshold_queue_url = "https://sqs.us-east-1.amazonaws.com/000000000000/fixture-threshold"

topic_namespace     = "telemetry"
tls_security_policy = "IoTSecurityPolicy_TLS13_1_2_2022_10"
retention_days      = 1826
log_retention_days  = 365
