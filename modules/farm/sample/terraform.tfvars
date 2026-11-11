# Synthetic, non-operational test fixtures only. No account or real endpoint is supplied.
client        = "fx"
project       = "cf"
environment   = "qa"
farm_id       = "fixture-a"
farm_key      = "a"
region        = "us-east-1"
plan_role_arn = ""
node_csr_paths = {
  crop   = "../tests/fixtures/crop.csr"
  drying = "../tests/fixtures/drying.csr"
}
ingestion = {
  environment = "qa", endpoint = "ingestion.example.invalid",
  policy_name = "fixture-policy", topic_template = "fixture/{thing_name}"
}
