# Native tests replace this provider with aws.principal's mock; no account plan is authorized.
provider "aws" {
  alias  = "principal"
  region = var.region
  dynamic "assume_role" {
    for_each = var.plan_role_arn == "" ? [] : [var.plan_role_arn]
    content {
      role_arn = assume_role.value
    }
  }
  default_tags {
    tags = local.common_tags
  }
}
