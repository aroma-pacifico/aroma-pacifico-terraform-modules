# Public lookup front door (CL-PUB-01): default action Block, the three managed rule groups, a rate-based
# rule per source IP scoped down to the sack path, and an allow rule for GET and HEAD on the lookup paths.
# The evaluation order follows the sack design: reputation, bad inputs, common, rate, allow.
resource "aws_wafv2_web_acl" "lookup" {
  provider = aws.project

  description = "Public sack lookup: default block, GET and HEAD on the lookup paths only"
  name        = "${var.name_prefix}-waf-lkp"
  scope       = var.waf_scope

  default_action {
    block {}
  }

  dynamic "rule" {
    for_each = local.managed_rule_groups

    content {
      name     = rule.value.key
      priority = rule.value.priority

      override_action {
        none {}
      }

      statement {
        managed_rule_group_statement {
          name        = rule.value.name
          vendor_name = "AWS"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${var.name_prefix}-lkp-${rule.value.key}"
        sampled_requests_enabled   = true
      }
    }
  }

  rule {
    name     = "rate-per-ip"
    priority = 40

    action {
      block {}
    }

    statement {
      rate_based_statement {
        aggregate_key_type    = "IP"
        evaluation_window_sec = 300
        limit                 = var.lookup_rate_limit

        scope_down_statement {
          byte_match_statement {
            positional_constraint = "STARTS_WITH"
            search_string         = var.lookup_rate_scope_path

            field_to_match {
              uri_path {}
            }

            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-lkp-rate"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "allow-read"
    priority = 50

    action {
      allow {}
    }

    statement {
      and_statement {
        statement {
          or_statement {
            statement {
              byte_match_statement {
                positional_constraint = "EXACTLY"
                search_string         = "GET"

                field_to_match {
                  method {}
                }

                text_transformation {
                  priority = 0
                  type     = "NONE"
                }
              }
            }

            statement {
              byte_match_statement {
                positional_constraint = "EXACTLY"
                search_string         = "HEAD"

                field_to_match {
                  method {}
                }

                text_transformation {
                  priority = 0
                  type     = "NONE"
                }
              }
            }
          }
        }

        statement {
          or_statement {
            statement {
              byte_match_statement {
                positional_constraint = "EXACTLY"
                search_string         = "/"

                field_to_match {
                  uri_path {}
                }

                text_transformation {
                  priority = 0
                  type     = "NONE"
                }
              }
            }

            dynamic "statement" {
              for_each = toset(var.lookup_allowed_path_prefixes)

              content {
                byte_match_statement {
                  positional_constraint = "STARTS_WITH"
                  search_string         = statement.value

                  field_to_match {
                    uri_path {}
                  }

                  text_transformation {
                    priority = 0
                    type     = "NONE"
                  }
                }
              }
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-lkp-allow"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.name_prefix}-lkp"
    sampled_requests_enabled   = true
  }

  tags = merge(local.governance_tags, local.rule_tags["CL-PUB-01"], { Name = "${var.name_prefix}-waf-lkp" })
}

# Public application API front door (CL-TEL-03): the same managed groups and a rate-based rule per source
# IP. Cognito token validation, not the web ACL, decides who may call, so the default action is Allow.
resource "aws_wafv2_web_acl" "api" {
  provider = aws.project

  description = "Public application API: managed rule groups and a rate limit per source address"
  name        = "${var.name_prefix}-waf-api"
  scope       = var.waf_scope

  default_action {
    allow {}
  }

  dynamic "rule" {
    for_each = local.managed_rule_groups

    content {
      name     = rule.value.key
      priority = rule.value.priority

      override_action {
        none {}
      }

      statement {
        managed_rule_group_statement {
          name        = rule.value.name
          vendor_name = "AWS"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${var.name_prefix}-api-${rule.value.key}"
        sampled_requests_enabled   = true
      }
    }
  }

  rule {
    name     = "rate-per-ip"
    priority = 40

    action {
      block {}
    }

    statement {
      rate_based_statement {
        aggregate_key_type    = "IP"
        evaluation_window_sec = 300
        limit                 = var.api_rate_limit
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-api-rate"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.name_prefix}-api"
    sampled_requests_enabled   = true
  }

  tags = merge(local.governance_tags, local.rule_tags["CL-TEL-03"], { Name = "${var.name_prefix}-waf-api" })
}
