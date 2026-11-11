# Event-driven inference function pattern (box D10). Per function: a queue that receives the event,
# a dead-letter queue, a log group, a role with the three permissions of the pattern, a Lambda
# function and the event source mapping that wakes it. The function exists only while it handles a
# message: there is no endpoint, no provisioned concurrency and no instance waiting for objects.

resource "aws_cloudwatch_log_group" "this" {
  for_each = var.functions

  provider = aws.project

  name              = "/aws/lambda/${local.names[each.key].function}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arns["logs"]

  tags = merge(local.governance_tags, { Name = "${local.names[each.key].function}-logs" })
}

resource "aws_sqs_queue" "dead_letter" {
  for_each = var.functions

  provider = aws.project

  name                      = local.names[each.key].dlq
  message_retention_seconds = 1209600 # 14 days, the SQS maximum (architecture section 6.1)
  kms_master_key_id         = var.kms_key_arns["records"]

  tags = merge(local.governance_tags, { Name = local.names[each.key].dlq })
}

resource "aws_sqs_queue" "this" {
  for_each = var.functions

  provider = aws.project

  name = local.names[each.key].queue
  # Six times the function timeout, so a message is not redelivered while its function still runs.
  visibility_timeout_seconds = 6 * each.value.timeout_seconds
  kms_master_key_id          = var.kms_key_arns["records"]

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter[each.key].arn
    maxReceiveCount     = each.value.max_receive_count
  })

  tags = merge(local.governance_tags, { Name = local.names[each.key].queue })
}

resource "aws_sqs_queue_redrive_allow_policy" "dead_letter" {
  for_each = var.functions

  provider = aws.project

  queue_url = aws_sqs_queue.dead_letter[each.key].id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.this[each.key].arn]
  })
}

# Only the named services, scoped by source ARN, may send to the queue, and plain HTTP is denied.
resource "aws_sqs_queue_policy" "this" {
  for_each = var.functions

  provider = aws.project

  queue_url = aws_sqs_queue.this[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [{
        Sid       = "DenyPlainHttp"
        Effect    = "Deny"
        Principal = "*"
        Action    = "sqs:*"
        Resource  = aws_sqs_queue.this[each.key].arn
        Condition = { Bool = { "aws:SecureTransport" = "false" } }
      }],
      length(each.value.queue_senders.service_principals) == 0 ? [] : [{
        Sid       = "AllowNamedSenders"
        Effect    = "Allow"
        Principal = { Service = each.value.queue_senders.service_principals }
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.this[each.key].arn
        Condition = { ArnEquals = { "aws:SourceArn" = each.value.queue_senders.source_arns } }
      }],
    )
  })
}

resource "aws_iam_role" "this" {
  for_each = var.functions

  provider = aws.project

  name                 = local.names[each.key].role
  permissions_boundary = var.permissions_boundary_arn

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = merge(local.governance_tags, { Name = local.names[each.key].role })
}

resource "aws_iam_role_policy" "this" {
  for_each = var.functions

  provider = aws.project

  name = "inference"
  role = aws_iam_role.this[each.key].id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = local.policy_statements[each.key]
  })
}

resource "aws_lambda_function" "this" {
  for_each = var.functions

  provider = aws.project

  # checkov:skip=CKV_AWS_116: The function is driven by an SQS event source mapping; failed messages go to the dead-letter queue of the source queue. The Lambda dead-letter setting only covers asynchronous invocation.
  # checkov:skip=CKV_AWS_117: Function placement is outside the VPC by design (non-VPC function placement in docs/architecture.md); calls reach AWS services over TLS with the least-privilege role.
  # checkov:skip=CKV_AWS_272: Code signing is outside the pilot scope; the package is supplied by the consuming root.
  # checkov:skip=CKV_AWS_50: Observability uses structured logs and metrics (architecture section 7); X-Ray tracing is not part of the design.

  function_name                  = local.names[each.key].function
  description                    = each.value.description
  role                           = aws_iam_role.this[each.key].arn
  handler                        = each.value.handler
  runtime                        = each.value.runtime
  filename                       = each.value.package.filename
  source_code_hash               = each.value.package.source_code_hash
  timeout                        = each.value.timeout_seconds
  memory_size                    = each.value.memory_mb
  reserved_concurrent_executions = each.value.reserved_concurrency
  kms_key_arn                    = var.kms_key_arns["records"]

  environment {
    variables = merge(each.value.environment_variables, local.result_environment, {
      MODEL_ID             = each.value.inference.model_id
      MODEL_REGION         = local.region
      BACKOFF_BASE_SECONDS = tostring(each.value.backoff_base_seconds)
    })
  }

  logging_config {
    log_format = "JSON"
    log_group  = aws_cloudwatch_log_group.this[each.key].name
  }

  tags = merge(local.governance_tags, { Name = local.names[each.key].function })

  depends_on = [aws_iam_role_policy.this]
}

# The trigger. Lambda polls the queue only while messages exist; a failed message becomes visible
# again after the visibility timeout (the function lengthens it for the backoff) and moves to the
# dead-letter queue after max_receive_count receives.
resource "aws_lambda_event_source_mapping" "this" {
  for_each = var.functions

  provider = aws.project

  event_source_arn                   = aws_sqs_queue.this[each.key].arn
  function_name                      = aws_lambda_function.this[each.key].arn
  batch_size                         = each.value.batch_size
  maximum_batching_window_in_seconds = 0
  function_response_types            = ["ReportBatchItemFailures"]

  tags = merge(local.governance_tags, { Name = "${local.names[each.key].function}-trigger" })
}
