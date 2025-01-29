output "ssm_parameter_names" {
  description = "Names of the SSM parameters created."
  value       = keys(aws_ssm_parameter.parameters)
}

output "ssm_parameter_arns" {
  description = "ARNs of the SSM parameters created."
  value       = [for p in aws_ssm_parameter.parameters : p.arn]
}
