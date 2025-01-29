variable "project_name" {
  type        = string
  description = "Project name."
}

variable "environment" {
  type        = string
  description = "Environment (e.g., dev, prod)."
}

variable "s3_bucket_name" {
  type        = string
  description = "Name of the S3 bucket hosting the website files."
}

variable "waf_arn" {
  type        = string
  default     = ""
  description = "ARN of the WAF web ACL (if any)."
}

variable "subenv_distributions" {
  type = list(object({
    subenv = string
  }))
  default = []
  description = <<EOT
A list of objects, each containing at least { subenv = "qa|uat|..." }.
We create one CloudFront distribution per entry.
EOT
}
