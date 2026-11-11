output "dead_letter_queue_names" {
  description = "Dead-letter queue name of each function."
  value       = module.inference_functions.dead_letter_queue_names
}

output "function_arns" {
  description = "Lambda function ARN of each function."
  value       = module.inference_functions.function_arns
}

output "key_user_arns" {
  description = "Role ARNs by key class, to pass to the security module."
  value       = module.inference_functions.key_user_arns
}

output "queue_arns" {
  description = "Trigger queue ARN of each function."
  value       = module.inference_functions.queue_arns
}
