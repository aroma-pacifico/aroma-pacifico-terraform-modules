locals {
  partition = data.aws_partition.current.partition
  region    = data.aws_region.current.region

  governance_tags = merge({
    Client      = var.client
    Project     = var.project
    Environment = var.environment
  }, var.additional_tags)

  # PC-IAC-003: {prefix}-{type}-{key}. The prefix is capped at 16 characters, the type code at 3 and
  # the key at 6, so no physical name exceeds 28 characters.
  names = {
    for key in keys(var.functions) : key => {
      function = "${var.name_prefix}-lmb-${key}"
      role     = "${var.name_prefix}-rol-${key}"
      queue    = "${var.name_prefix}-sqs-${key}"
      dlq      = "${var.name_prefix}-dlq-${key}"
    }
  }

  # The records key always protects the queues and the environment variables, so every function
  # decrypts with it. Write classes also generate data keys. The classes are limited to telemetry,
  # objects and records by variable validation.
  decrypt_classes  = { for key, f in var.functions : key => distinct(concat(["records"], f.read.kms_classes, f.write.kms_classes)) }
  generate_classes = { for key, f in var.functions : key => distinct(f.write.kms_classes) }

  # A function reads and writes through the Bedrock foundation model it names, never through an
  # inference profile (architecture section 11).
  model_arns = { for key, f in var.functions : key => "arn:${local.partition}:bedrock:${local.region}::foundation-model/${f.inference.model_id}" }

  # Defence in depth: an explicit deny on the two key classes no inference function may use.
  denied_key_arns = compact([for class in ["personal", "restricted"] : lookup(var.kms_key_arns, class, null)])

  # Names of the three result attributes reach the function code as environment variables.
  result_environment = {
    RESULT_TIMESTAMP_ATTRIBUTE     = var.result_record_attributes.timestamp
    RESULT_CONFIDENCE_ATTRIBUTE    = var.result_record_attributes.confidence
    RESULT_SOURCE_OBJECT_ATTRIBUTE = var.result_record_attributes.source_object
  }

  # One statement list per function; empty grants add no statement. Statements are plain objects so
  # that the plan-mode tests can assert them.
  policy_statements = {
    for key, f in var.functions : key => concat(
      [
        {
          Sid      = "WriteOwnLogs"
          Effect   = "Allow"
          Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
          Resource = ["${aws_cloudwatch_log_group.this[key].arn}:*"]
        },
        {
          Sid      = "ConsumeOwnQueue"
          Effect   = "Allow"
          Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes", "sqs:ChangeMessageVisibility"]
          Resource = [aws_sqs_queue.this[key].arn]
        },
        {
          Sid      = "DecryptWithGrantedKeys"
          Effect   = "Allow"
          Action   = ["kms:Decrypt"]
          Resource = [for class in local.decrypt_classes[key] : var.kms_key_arns[class]]
        },
        {
          Sid      = "InvokeOneFoundationModel"
          Effect   = "Allow"
          Action   = ["bedrock:InvokeModel"]
          Resource = [local.model_arns[key]]
        },
        {
          Sid      = "NeverWriteObjects"
          Effect   = "Deny"
          Action   = ["s3:PutObject", "s3:DeleteObject", "s3:DeleteObjectVersion"]
          Resource = ["*"]
        },
      ],
      length(f.read.s3_object_arns) == 0 ? [] : [{
        Sid      = "ReadPersistedObjects"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:GetObjectVersion"]
        Resource = f.read.s3_object_arns
      }],
      length(f.read.dynamodb_table_arns) == 0 ? [] : [{
        Sid      = "ReadPersistedRecords"
        Effect   = "Allow"
        Action   = ["dynamodb:GetItem", "dynamodb:Query"]
        Resource = f.read.dynamodb_table_arns
      }],
      length(f.write.dynamodb_table_arns) == 0 ? [] : [{
        Sid      = "WriteResultRecord"
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem", "dynamodb:UpdateItem", "dynamodb:ConditionCheckItem"]
        Resource = f.write.dynamodb_table_arns
      }],
      length(f.write.sns_topic_arns) == 0 ? [] : [{
        Sid      = "PublishAlerts"
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = f.write.sns_topic_arns
      }],
      length(local.generate_classes[key]) == 0 ? [] : [{
        Sid      = "GenerateDataKeysForResultWrites"
        Effect   = "Allow"
        Action   = ["kms:GenerateDataKey"]
        Resource = [for class in local.generate_classes[key] : var.kms_key_arns[class]]
      }],
      length(local.denied_key_arns) == 0 ? [] : [{
        Sid      = "NeverUsePersonalOrRestrictedKeys"
        Effect   = "Deny"
        Action   = ["kms:*"]
        Resource = local.denied_key_arns
      }],
    )
  }

  # Role ARNs by key class, in the shape of the key_user_arns input of the security module. They
  # depend only on the roles, never on the policies, so the two modules do not form a cycle.
  key_user_role_arns = {
    for class in distinct(flatten(values(local.decrypt_classes))) : class => [
      for key, classes in local.decrypt_classes : aws_iam_role.this[key].arn if contains(classes, class)
    ]
  }
}
