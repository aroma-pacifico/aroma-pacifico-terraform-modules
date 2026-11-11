# One invocation of the security module; all security logic stays inside the reusable module.
module "security" {
  source = "../"

  providers = { aws.project = aws.principal }

  client                        = var.client
  project                       = var.project
  environment                   = var.environment
  name_prefix                   = local.name_prefix
  additional_tags               = local.common_tags
  key_administrator_arns        = var.key_administrator_arns
  key_user_arns                 = var.key_user_arns
  break_glass_role_arn_patterns = var.break_glass_role_arn_patterns
  protected_bucket_arns         = var.protected_bucket_arns
}
