variable "aws_region" {
  type    = string
  default = "us-east-1"  # or your preferred region
}

variable "vpc_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "public_subnets_cidr" {
  type    = list(string)
  default = ["10.1.2.0/24", "10.1.3.0/24"]
}

variable "private_subnets_cidr" {
  type    = list(string)
  default = ["10.1.0.0/24", "10.1.1.0/24"]
}

variable "project_name" {
  type    = string
  default = "fanduel"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "subenv" {
  type    = list(string)
  default = ["qa", "uat"]
  description = "List of sub-environments (e.g., qa, uat)."
}

variable "dynamodb_tables" {
  description = "List of DynamoDB table configurations."
  type = list(object({
    name                = string
    partition_key       = string
    billing_mode        = optional(string, "PAY_PER_REQUEST")
    pitr_enabled        = optional(bool, true)
    deletion_protection = optional(bool, true)
  }))
  default = []
}

variable "acm_certificates" {
  type = list(object({
    subenv             = string
    domain             = string
    subdomains         = list(string)
    validation_enabled = bool
    hosted_zone_id     = string
  }))
  default = []
}

variable "waf_arn" {
  type    = string
  default = ""
}

variable "aliases" {
  type        = list(string)
  description = "List of CNAMEs (alternate domain names) for the CloudFront distribution."
  default     = []
}

variable "price_class" {
  type        = string
  default     = "PriceClass_100"
  description = "Price class for the CloudFront distribution."
}

variable "web_acl_id" {
  type        = string
  description = "AWS WAF Web ACL ID to associate with the CloudFront distribution."
  default     = null
}

variable "logging_config" {
  type = object({
    bucket = string
    prefix = string
  })
  description = "Configuration for CloudFront access logs."
  default     = null
}