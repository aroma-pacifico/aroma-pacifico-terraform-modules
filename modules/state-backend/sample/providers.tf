# Native tests inject a mock. A real account plan is not authorized by this example.
provider "aws" {
  alias               = "principal"
  region              = var.configuration.aws_context.region
  allowed_account_ids = [var.configuration.aws_context.account_id]
  assume_role { role_arn = var.configuration.execution_role_arn }
  default_tags { tags = local.common_tags }
}
