############################################################
# Lambda With Layer Module Variables
############################################################

variable "project_name" {
  type        = string
  description = "Project name for resource naming."
}

variable "subenv" {
  type        = string
  description = "Sub-environment name (e.g., qa, uat)."
}

variable "environment" {
  type        = string
  description = "Environment name (e.g., dev, prod)."
}

variable "lambda_execution_role_arn" {
  type        = string
  description = "IAM Role ARN for Lambda execution."
}

variable "runtime" {
  type        = string
  default     = "python3.9"
  description = "Runtime for the Lambda functions."
}

variable "layer_s3_bucket" {
  type        = string
  description = "S3 bucket containing the layer artifact."
}

variable "layer_s3_key" {
  type        = string
  description = "S3 key (object path) for the layer ZIP artifact."
}

variable "layer_description" {
  type        = string
  default     = "Common layer for multiple Lambdas"
  description = "Description for the Lambda layer."
}

variable "lambda_definitions" {
  type = list(object({
    name        = string
    handler     = string
    memory_size = number
    timeout     = number
    # Optionally add environment variables or other fields
  }))
  description = <<EOT
List of Lambda configuration objects. Each object should contain:
- name        = "my-lambda-name"
- handler     = "index.handler"
- memory_size = 128
- timeout     = 5
EOT
}

variable "source_code_s3_bucket" {
  type        = string
  description = "Name of the S3 bucket containing the Lambda function code."
}

variable "source_code_s3_key" {
  type        = string
  description = "S3 key (object path) to the Lambda function code ZIP."
}

# If you still want Function URLs restricted to CloudFront, keep or remove as needed:
variable "enable_function_urls" {
  type        = bool
  default     = true
  description = "Whether to create Lambda function URLs and restrict them to cloudfront.amazonaws.com."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for Lambda VPC configuration."
}

variable "security_group_ids" {
  type        = list(string)
  description = "List of security group IDs for Lambda VPC configuration."
}