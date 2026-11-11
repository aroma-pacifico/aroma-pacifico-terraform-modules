// Main Terraform configuration for inference functions module
// This module defines IAM role, SQS queues, dead-letter queues, and placeholder Lambda functions

resource "aws_iam_role" "inference_functions_role" {
  name = var.name_prefix != "" ? "${var.name_prefix}-inference-functions" : "inference-functions"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })

  // Permissions for Bedrock, DynamoDB, S3 (adjust as needed)
  inline_policy {
    name = "inference-permissions"
    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Effect   = "Allow",
          Action   = ["bedrock:InvokeModel"],
          Resource = "*"
        },
        {
          Effect   = "Allow",
          Action   = ["dynamodb:GetItem", "dynamodb:Query"],
          Resource = "*"
        },
        {
          Effect   = "Allow",
          Action   = ["s3:GetObject"],
          Resource = "arn:aws:s3:::${var.s3_bucket_name}/*"
        }
      ]
    })
  }
}

// SQS queues and DLQs for each function
resource "aws_sqs_queue" "function_queue" {
  for_each = var.functions

  name                       = "${var.name_prefix != "" ? var.name_prefix : ""}-${each.key}-queue"
  visibility_timeout_seconds = 30
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[each.key].arn
    maxReceiveCount     = 5
  })
}

resource "aws_sqs_queue" "dlq" {
  for_each = var.functions

  name = "${var.name_prefix != "" ? var.name_prefix : ""}-${each.key}-dlq"
}

// Placeholder Lambda functions (code to be provided elsewhere)
resource "aws_lambda_function" "function" {
  for_each = var.functions

  function_name = "${var.name_prefix != "" ? var.name_prefix : ""}-${each.key}"
  runtime       = "python3.12"
  handler       = "index.handler"
  filename      = "${var.lambda_source_path}/${each.key}.zip"
  role          = aws_iam_role.inference_functions_role.arn

  // Minimal configuration – actual code is external
  timeout = 60
}
