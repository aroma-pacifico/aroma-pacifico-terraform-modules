output "dead_letter_queue_arns" {
  description = "ARN of the dead-letter queue of each function, keyed by function key."
  value       = { for key, queue in aws_sqs_queue.dead_letter : key => queue.arn }
}

output "dead_letter_queue_names" {
  description = "Name of the dead-letter queue of each function, for the alarms on the first message."
  value       = { for key, queue in aws_sqs_queue.dead_letter : key => queue.name }
}

output "event_source_mapping_uuids" {
  description = "UUID of the SQS event source mapping of each function."
  value       = { for key, mapping in aws_lambda_event_source_mapping.this : key => mapping.uuid }
}

output "function_arns" {
  description = "ARN of each Lambda function, keyed by function key."
  value       = { for key, function in aws_lambda_function.this : key => function.arn }
}

output "function_names" {
  description = "Name of each Lambda function, keyed by function key."
  value       = { for key, function in aws_lambda_function.this : key => function.function_name }
}

output "key_user_arns" {
  description = "Role ARNs by key class (telemetry, objects, records), in the shape of the key_user_arns input of the security module. The roots pass this to the security module so the key policies name the function roles."
  value       = local.key_user_role_arns
}

output "log_group_names" {
  description = "Log group name of each function, keyed by function key."
  value       = { for key, group in aws_cloudwatch_log_group.this : key => group.name }
}

output "queue_arns" {
  description = "ARN of the trigger queue of each function. The upstream rule, pipe or topic rule targets this queue."
  value       = { for key, queue in aws_sqs_queue.this : key => queue.arn }
}

output "queue_names" {
  description = "Name of the trigger queue of each function, for the age-of-oldest-message alarms."
  value       = { for key, queue in aws_sqs_queue.this : key => queue.name }
}

output "queue_urls" {
  description = "URL of the trigger queue of each function."
  value       = { for key, queue in aws_sqs_queue.this : key => queue.url }
}

output "result_record_attributes" {
  description = "Attribute names under which every function persists the timestamp, the confidence and the source object identifier."
  value       = var.result_record_attributes
}

output "role_arns" {
  description = "ARN of the execution role of each function. These depend only on the roles."
  value       = { for key, role in aws_iam_role.this : key => role.arn }
}
