variable "project_name" {
  type        = string
  description = "Project name for naming/tagging."
}

variable "environment" {
  type        = string
  description = "Environment name (e.g., 'dev' or 'prod')."
}

variable "block_public_access" {
  type        = bool
  default     = true
  description = "Whether to enable block public access for the bucket."
}

variable "cloudfront_distribution_ids" {
  type        = list(string)
  default     = []
  description = <<EOT
List of CloudFront distribution IDs that should be allowed
to read from this bucket (via Origin Access Control).
If empty, no policy statement is added.
EOT
}
  
variable "waf_account_id" {
  type        = string
  default     = ""
  description = <<EOT
(Optional) AWS Account ID used when constructing the SourceArn condition for CloudFront.
If not provided, we'll detect it with data.aws_caller_identity.current.
EOT
}
