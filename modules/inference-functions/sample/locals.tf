# Roots construct governance names and tags, then pass them to the module.
locals {
  name_prefix = "${var.client}-${var.project}-${var.environment}"

  common_tags = {
    Client      = var.client
    Project     = var.project
    Environment = var.environment
    Owner       = "SR1"
    CostCenter  = "shared"
  }

  # Design values of ASM-160 to ASM-162 (architecture sections 3 and 6.1), one entry per trigger of
  # Part E. The three drone functions share one shape and differ in the mission prefix they read.
  # Fixture ARNs only: a real root passes the table, bucket and topic ARNs of its own account.
  drone_function = {
    package   = { filename = "build/placeholder.zip" }
    inference = { model_id = var.model_id }
    read = {
      s3_object_arns      = [var.drone_object_bucket_arn_pattern]
      dynamodb_table_arns = [var.mission_table_arn]
      kms_classes         = ["objects"]
    }
    write = {
      dynamodb_table_arns = [var.mission_table_arn]
      kms_classes         = ["records"]
    }
    queue_senders = {
      service_principals = ["events.amazonaws.com"]
      source_arns        = [var.event_rule_arn_pattern]
    }
  }

  functions = {
    confrm = merge(local.drone_function, { description = "Confirms a pest focus from the confirmation mission objects." })
    verify = merge(local.drone_function, { description = "Verifies that a fumigated focus can close." })
    estim  = merge(local.drone_function, { description = "Estimates the crop load from the estimation mission objects." })
    thresh = {
      description          = "Evaluates a telemetry batch and labels the plausibility of an alert opening."
      package              = { filename = "build/placeholder.zip" }
      timeout_seconds      = 60
      memory_mb            = 256
      batch_size           = 10
      reserved_concurrency = 10
      backoff_base_seconds = 10
      inference            = { model_id = var.model_id }
      read = {
        dynamodb_table_arns = [var.telemetry_table_arn, var.thresholds_table_arn]
        kms_classes         = ["telemetry"]
      }
      write = {
        dynamodb_table_arns = [var.alert_table_arn]
        sns_topic_arns      = [var.alert_topic_arn]
        kms_classes         = ["records"]
      }
      queue_senders = {
        service_principals = ["iot.amazonaws.com"]
        source_arns        = [var.iot_rule_arn]
      }
    }
  }
}
