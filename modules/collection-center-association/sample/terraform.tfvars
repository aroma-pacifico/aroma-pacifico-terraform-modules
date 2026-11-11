# Synthetic, non-operational fixtures. They feed the Floci speculative plan in CI and the
# Infracost scan; native tests override them with their own generated values.
center = {
  key        = "cauca"
  cidr_block = "10.41.0.0/16"
}
network = {
  environment                   = "pdn"
  account_id                    = "000000000000"
  vpc_id                        = "vpc-0123456789abcdef0"
  vpc_cidr_block                = "10.82.0.0/16"
  transit_attachment_subnet_ids = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1", "subnet-0123456789abcdef2"]
}
hub = {
  account_id               = "000000000001"
  region                   = "us-east-1"
  transit_gateway_id       = "tgw-0123456789abcdef0"
  customer_certificate_arn = "arn:aws:acm:us-east-1:000000000001:certificate/00000000-0000-0000-0000-000000000000"
}
