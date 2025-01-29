resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  price_class         = var.price_class
  aliases             = var.aliases
  web_acl_id          = var.web_acl_id

  origin {
    domain_name = var.lambda_function_urls[var.default_cache_behavior.target_origin_id]
    origin_id   = var.default_cache_behavior.target_origin_id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods  = var.default_cache_behavior.allowed_methods
    cached_methods   = var.default_cache_behavior.cached_methods
    target_origin_id = var.default_cache_behavior.target_origin_id

    forwarded_values {
      query_string = var.default_cache_behavior.forwarded_values.query_string
      headers      = var.default_cache_behavior.forwarded_values.headers
      cookies {
        forward = var.default_cache_behavior.forwarded_values.cookies.forward
      }
    }

    viewer_protocol_policy = var.default_cache_behavior.viewer_protocol_policy
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  viewer_certificate {
    acm_certificate_arn = var.acm_certificate_arns[var.domain_names[0]]
    ssl_support_method  = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  logging_config {
    bucket = var.logging_config.bucket
    prefix = var.logging_config.prefix
  }

  tags = var.tags
}