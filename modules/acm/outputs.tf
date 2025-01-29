output "certificate_arns" {
  description = "ARNs of the ACM certificates"
  value       = { for k, v in aws_acm_certificate.this : k => v.arn }
}

output "domain_names" {
  description = "List of domain names on the certificates"
  value       = { for k, v in aws_acm_certificate.this : k => v.domain_name }
}

output "validation_statuses" {
  description = "Validation statuses of the certificates. Returns an empty map if validation is disabled."
  value       = var.validation_enabled ? { for k, v in aws_acm_certificate_validation.this : k => v.id } : {}
}