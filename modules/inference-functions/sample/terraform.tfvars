# Synthetic fixtures: client and project are placeholders, the zero account is the documented
# fixture value, and no real account, hostname, bucket or table is supplied.
client      = "fx"
project     = "cf"
environment = "pdn"
region      = "us-east-1"

model_id = "amazon.nova-pro-v1:0"

kms_key_arns = {
  telemetry  = "arn:aws:kms:us-east-1:000000000000:key/00000000-0000-0000-0000-000000000001"
  objects    = "arn:aws:kms:us-east-1:000000000000:key/00000000-0000-0000-0000-000000000002"
  records    = "arn:aws:kms:us-east-1:000000000000:key/00000000-0000-0000-0000-000000000003"
  personal   = "arn:aws:kms:us-east-1:000000000000:key/00000000-0000-0000-0000-000000000004"
  logs       = "arn:aws:kms:us-east-1:000000000000:key/00000000-0000-0000-0000-000000000005"
  restricted = "arn:aws:kms:us-east-1:000000000000:key/00000000-0000-0000-0000-000000000008"
}

mission_table_arn               = "arn:aws:dynamodb:us-east-1:000000000000:table/fixture-missions"
telemetry_table_arn             = "arn:aws:dynamodb:us-east-1:000000000000:table/fixture-telemetry"
thresholds_table_arn            = "arn:aws:dynamodb:us-east-1:000000000000:table/fixture-thresholds"
alert_table_arn                 = "arn:aws:dynamodb:us-east-1:000000000000:table/fixture-alerts"
alert_topic_arn                 = "arn:aws:sns:us-east-1:000000000000:fixture-alerts"
drone_object_bucket_arn_pattern = "arn:aws:s3:::fixture-drone-objects/farms/*"
event_rule_arn_pattern          = "arn:aws:events:us-east-1:000000000000:rule/fixture-drone-service/*"
iot_rule_arn                    = "arn:aws:iot:us-east-1:000000000000:rule/fixture_telemetry"
