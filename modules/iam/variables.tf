variable "project_name" {
  type        = string
  description = "Project name for tagging."
}

variable "environment" {
  type        = string
  description = "Environment (e.g., dev or prod) for tagging."
}

variable "lambda_role_name" {
  type        = string
  description = "Optional override for the Lambda execution role name."
  default     = ""
}

variable "dynamodb_access" {
  type        = bool
  description = "Whether to grant Lambda read/write access to all DynamoDB tables."
  default     = true
}

variable "ssm_parameter_paths" {
  type = list(string)
  description = <<EOT
List of parameter paths/ARNs that the Lambda is allowed to read.
For example: ["/myapp/config/", "/anotherapp/config/secret"]
EOT
  default = []
}
