output "layer_arn" {
  description = "ARN of the common Lambda layer."
  value       = aws_lambda_layer_version.common_layer.arn
}

output "lambda_function_arns" {
  description = "Map of Lambda function ARNs keyed by function name."
  value = {
    for name, fn in aws_lambda_function.functions :
    name => fn.arn
  }
}

output "lambda_function_names" {
  description = "Map of Lambda function names keyed by definition name."
  value = {
    for name, fn in aws_lambda_function.functions :
    name => fn.function_name
  }
}

output "lambda_function_urls" {
  description = "Map of Lambda Function URLs keyed by function name (only if enabled)."
  value = {
    for name, fn_url in aws_lambda_function_url.function_urls :
    name => fn_url.function_url
  }
}
