variable "configuration" {
  description = "One environment's root configuration. Real identities must come from B03/B06, not this fixture."
  type = object({
    client                = string
    project               = string
    environment           = string
    resource_key          = string
    aws_context           = object({ account_id = string, partition = string, region = string })
    execution_role_arn    = string
    owner                 = string
    cost_center           = string
    key_administrators    = set(string)
    configuration_readers = set(string)
    domain_access         = map(object({ plan_role_arns = set(string), write_role_arns = optional(set(string), []) }))
  })
  nullable = false
  validation {
    condition     = contains(["dev", "qa", "pdn"], var.configuration.environment) && var.configuration.aws_context.region == "us-east-1"
    error_message = "Use one approved environment in the primary us-east-1 Region."
  }
  validation {
    condition     = can(regex("^arn:${var.configuration.aws_context.partition}:iam::${var.configuration.aws_context.account_id}:role/[A-Za-z0-9+=,.@_/-]+$", var.configuration.execution_role_arn))
    error_message = "An explicit same-account execution-role reference is required; credentials are never input."
  }
  validation {
    condition     = toset(keys(var.configuration.domain_access)) == toset(["network", "security", "workload", "state-backend"])
    error_message = "The project composition must cover all four approved state domains."
  }
}
