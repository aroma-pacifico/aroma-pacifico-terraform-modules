# Native tests replace this provider with aws.principal's mock; no account plan is authorized.
provider "aws" {
  alias  = "principal"
  region = var.region
  assume_role {
    role_arn = var.plan_role_arn
  }
  default_tags {
    tags = local.common_tags
  }
}
