output "iam_role_arn" {
  description = "ARN of the IAM role for inference functions"
  value       = aws_iam_role.inference_functions_role.arn
}

output "queue_arns" {
  description = "Map of function name to its SQS queue ARN"
  value       = { for k, v in aws_sqs_queue.function_queue : k => v.arn }
}

output "dlq_arns" {
  description = "Map of function name to its dead-letter queue ARN"
  value       = { for k, v in aws_sqs_queue.dlq : k => v.arn }
}

output "lambda_arns" {
  description = "Map of function name to its Lambda ARN"
  value       = { for k, v in aws_lambda_function.function : k => v.arn }
}
