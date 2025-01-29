variable "project_name" {
  type        = string
  description = "Project name for tagging."
}

variable "environment" {
  type        = string
  description = "Environment name (e.g., dev, prod) for tagging."
}

variable "dynamodb_tables" {
  description = <<EOT
List of objects describing each DynamoDB table to create.
Each object should contain:
  name                = string  (the DynamoDB table name)
  partition_key       = string  (the primary partition key name)
  billing_mode        = string  (e.g., "PAY_PER_REQUEST" or "PROVISIONED")
  pitr_enabled        = bool    (true/false)
  deletion_protection = bool    (true/false)
EOT
  type = list(object({
    name                = string
    partition_key       = string
    billing_mode        = string
    pitr_enabled        = bool
    deletion_protection = bool
  }))
  default = []
}
