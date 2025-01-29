variable "project_name" {
  type        = string
  description = "Project name for tagging."
}

variable "environment" {
  type        = string
  description = "Environment name (e.g., 'dev' or 'prod') for tagging."
}

variable "subenv" {
  type        = string
  description = <<EOT
Sub-environment within the account.
Examples: "qa", "uat", or "prod".
If subenv == "prod", we drop the prefix. Otherwise we use {subenv}.{domain}.
EOT
}

variable "domain" {
  type        = string
  description = "Base domain (e.g., 'subdomain.example.com')."
}

variable "subdomains" {
  type        = list(string)
  default     = ["app", "api"]
  description = <<EOT
List of sub-subdomains that will be appended to
{subenv}.{domain} (except for 'prod' where it is just {domain}).
So if subenv='qa' and domain='subdomain.example.com',
we generate: app.qa.subdomain.example.com, api.qa.subdomain.example.com, etc.
EOT
}

variable "validation_enabled" {
  type        = bool
  default     = true
  description = "Whether to create Route53 DNS validation records automatically."
}

variable "hosted_zone_id" {
  type        = string
  default     = ""
  description = <<EOT
Route53 Hosted Zone ID where DNS validation records should be created.
If validation_enabled = false, this won't be used.
For dev accounts, it might be the zone of 'qa.chuck.example.com' or 'uat.chuck.example.com';
for prod, the zone of 'chuck.example.com'.
EOT
}
