variable "lambda_function_urls" {
  type        = map(string)
  description = "Map of Lambda Function URLs to use as origins in CloudFront."
}

variable "acm_certificate_arns" {
  type        = map(string)
  description = "Map of ACM certificate ARNs for the domains."
}

variable "domain_names" {
  type        = list(string)
  description = "List of domain names that CloudFront will serve."
}

variable "aliases" {
  type        = list(string)
  description = "List of CNAMEs (alternate domain names) for the CloudFront distribution."
  default     = []
}

variable "default_cache_behavior" {
  type = object({
    allowed_methods  = list(string)
    cached_methods   = list(string)
    target_origin_id = string
    forwarded_values = object({
      query_string = bool
      headers      = list(string)
      cookies      = object({
        forward = string
      })
    })
    viewer_protocol_policy = string
  })
}

variable "logging_config" {
  type = object({
    bucket = string
    prefix = string
  })
  description = "Configuration for CloudFront access logs."
  default     = null
}

variable "price_class" {
  type        = string
  description = "Price class for the CloudFront distribution."
  default     = "PriceClass_100"
}

variable "web_acl_id" {
  type        = string
  description = "AWS WAF Web ACL ID to associate with the CloudFront distribution."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to assign to the CloudFront distribution."
  default     = {}
}