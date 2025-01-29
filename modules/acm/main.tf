locals {
  # If subenv is "prod", use the domain as-is (e.g. chuck.example.com).
  # Otherwise, prefix it (e.g. "qa.chuck.example.com").
  effective_root_domain = var.subenv == "prod" ? var.domain : "${var.subenv}.${var.domain}"

  # Build a list of fully qualified domain names for each entry in subdomains.
  # e.g. "app.qa.chuck.example.com", "api.qa.chuck.example.com" (dev)
  # or "app.chuck.example.com", "api.chuck.example.com" (prod)
  all_domains = [
    for sub in var.subdomains :
    "${sub}.${local.effective_root_domain}"
  ]
}

# Create a certificate for each subdomain
resource "aws_acm_certificate" "this" {
  for_each = toset(local.all_domains)

  domain_name               = each.value
  validation_method         = "DNS"

  # Tagging
  tags = {
    Name        = "${var.project_name}-${var.environment}-acm-${replace(each.value, ".", "-")}"
    Project     = var.project_name
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create validation records only if "validation_enabled = true"
# We can accomplish this by using a for_each that is empty when validation is disabled.
locals {
  dvo_map = var.validation_enabled ? { for dvo in flatten([for cert in aws_acm_certificate.this : cert.domain_validation_options]) : dvo.domain_name => dvo } : {}
}

resource "aws_route53_record" "validation" {
  for_each = local.dvo_map

  zone_id = var.hosted_zone_id

  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  ttl     = 60
  records = [each.value.resource_record_value]
}

# Only create aws_acm_certificate_validation if validation is enabled
resource "aws_acm_certificate_validation" "this" {
  for_each = var.validation_enabled ? aws_acm_certificate.this : {}

  certificate_arn         = each.value.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn if record.name == each.value.domain_name]

  # Use depends_on to ensure records are created first
  depends_on = [
    aws_route53_record.validation
  ]
}