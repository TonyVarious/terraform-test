locals {
  # Turn list into map keyed by subenv => object
  subenv_map = {
    for item in var.subenv_distributions :
    item.subenv => item
  }
}

resource "aws_cloudfront_origin_access_control" "oac" {
  for_each = local.subenv_map

  name        = "${var.project_name}-${each.value.subenv}-oac"
  description = "OAC for ${var.project_name}-${each.value.subenv}"

  origin_access_control_origin_type = "s3"
  signing_behavior      = "always"
  signing_protocol      = "sigv4"
}

resource "aws_cloudfront_distribution" "this" {
  for_each = local.subenv_map

  enabled             = true
  comment             = "${var.project_name}-${each.value.subenv}-web"
  default_root_object = "index.html"

  origin {
    domain_name = "${var.s3_bucket_name}.s3.amazonaws.com"
    origin_id   = "${var.project_name}-${each.value.subenv}-web"
    origin_path = "/${each.value.subenv}"

    origin_access_control_id = aws_cloudfront_origin_access_control.oac[each.key].id
  }

default_cache_behavior {
  target_origin_id       = "${var.project_name}-${each.value.subenv}-web"
  viewer_protocol_policy = "redirect-to-https"

  allowed_methods  = ["GET", "HEAD"]
  cached_methods   = ["GET", "HEAD"]
  compress         = true

  # REQUIRED: forwarded_values
  forwarded_values {
    query_string = false  # or true if you need to forward query strings

    cookies {
      forward = "none"  # 'none', 'all', or 'whitelist'
    }
  }
}
  custom_error_response {
    error_code             = 403
    response_page_path     = "/index.html"
    response_code          = 200
    error_caching_min_ttl  = 10
  }

  custom_error_response {
    error_code             = 404
    response_page_path     = "/index.html"
    response_code          = 200
    error_caching_min_ttl  = 10
  }
  web_acl_id = var.waf_arn != "" ? var.waf_arn : null

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name        = "${var.project_name}-${each.value.subenv}-web"
    Project     = var.project_name
    Environment = var.environment
    Subenv      = each.value.subenv
  }
}
