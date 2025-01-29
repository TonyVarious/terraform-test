terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # or your preferred version
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"
  
  vpc_cidr             = var.vpc_cidr
  public_subnets_cidr  = var.public_subnets_cidr
  private_subnets_cidr = var.private_subnets_cidr
  project_name         = var.project_name
  environment          = var.environment
}

module "iam" {
  source = "./modules/iam"

  project_name        = var.project_name
  environment         = var.environment
  lambda_role_name    = "lambda-execution-role"  # Let the module generate a name
  dynamodb_access     = true

  # We'll allow SSM read to the following paths
  ssm_parameter_paths = [
    "/myapp/config/",
    "/myapp/another/"
  ]
}

module "ssm" {
  source = "./modules/ssm"

  project_name   = var.project_name
  environment    = var.environment
  ssm_parameters = {
    "/app/openai_key" = "sk-test"
  }
  parameter_type = "SecureString"
}

output "lambda_execution_role_arn" {
  value = module.iam.lambda_execution_role_arn
}

output "ssm_parameter_arns" {
  value = module.ssm.ssm_parameter_arns
}

# Example usage of the Lambda module
module "lambda_module" {
  for_each = toset(var.subenv)
  source = "./modules/lambda"

  source_code_s3_bucket        = "fanduel-test-lambda"
  source_code_s3_key           = "appLayer.zip"
  layer_s3_bucket              = "fanduel-test-lambda"
  layer_s3_key                 = "appLayer.zip"
  lambda_execution_role_arn    = module.iam.lambda_execution_role_arn

  lambda_definitions = [
    {
      name        = "${var.project_name}-${each.key}-openai"
      handler     = "handlers.openAiCall"
      memory_size = 128
      timeout     = 60
    },
    {
      name        = "${var.project_name}-${each.key}-handler2"
      handler     = "index.handler2"
      memory_size = 128
      timeout     = 10
    }
    # Add more definitions if needed
  ]

  project_name = var.project_name
  environment  = var.environment
  runtime      = "nodejs22.x"
  subenv       = each.key  # Pass the subenv value to the module

  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_ids = [module.vpc.lambda_security_group_id]
}


module "dynamodb" {
  source         = "./modules/dynamodb"
  project_name   = var.project_name
  environment    = var.environment
  dynamodb_tables = flatten([
    for table in var.dynamodb_tables : [
      for subenv in var.subenv : {
        name                = "${table.name}-${subenv}"
        partition_key       = table.partition_key
        billing_mode        = table.billing_mode
        pitr_enabled        = table.pitr_enabled
        deletion_protection = table.deletion_protection
      }
    ]
  ])
}

module "acm" {
  # for_each creates one ACM module instance per subenv.
  for_each = { for c in var.acm_certificates : c.subenv => c }

  source = "./modules/acm"

  # Pass along project-level variables
  project_name = var.project_name
  environment  = var.environment

  # Map each object to the module inputs
  subenv             = each.value.subenv
  domain             = each.value.domain
  subdomains         = each.value.subdomains
  validation_enabled = each.value.validation_enabled
  hosted_zone_id     = each.value.hosted_zone_id
}

output "acm_certificate_arns" {
  description = "ARNs of all ACM certificates"
  value       = { for k, v in module.acm : k => v.certificate_arns }
}

module "s3_web" {
  source       = "./modules/s3_web"
  project_name = var.project_name
  environment  = var.environment

  # If your module automatically creates a bucket policy, you could disable it
  # or pass an empty distribution list for now. 
  # E.g., cloudfront_distribution_ids = []
}

module "cloudfront_frontend" {
  source = "./modules/cloudfront_frontend"

  project_name       = var.project_name
  environment        = var.environment
  s3_bucket_name     = module.s3_web.bucket_name
  waf_arn            = var.waf_arn
  
  # Convert ["qa", "uat"] => [{ subenv = "qa" }, { subenv = "uat" }]
  subenv_distributions = [
    for s in var.subenv : {
      subenv = s
    }
  ]
}

data "aws_caller_identity" "current" {}

# Build a policy document that:
# - Denies non-HTTPS traffic (optional)
# - Allows each distribution ID to s3:GetObject
data "aws_iam_policy_document" "s3_bucket_policy" {
  statement {
    sid     = "DenyNonHTTPS"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      "arn:aws:s3:::${module.s3_web.bucket_name}",
      "arn:aws:s3:::${module.s3_web.bucket_name}/*"
    ]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  # Loop over each distribution ID and allow it
  dynamic "statement" {
    for_each = module.cloudfront_frontend.distribution_ids
    content {
      sid     = "AllowCF-${statement.key}"
      effect  = "Allow"
      actions = ["s3:GetObject"]
      resources = [
        "arn:aws:s3:::${module.s3_web.bucket_name}/*"
      ]
      principals {
        type        = "Service"
        identifiers = ["cloudfront.amazonaws.com"]
      }
      condition {
        test     = "StringEquals"
        variable = "AWS:SourceArn"
        values = [
          "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${statement.value}"
        ]
      }
    }
  }
}

resource "aws_s3_bucket_policy" "allow_cloudfront" {
  bucket = module.s3_web.bucket_name
  policy = data.aws_iam_policy_document.s3_bucket_policy.json

  # IMPORTANT: Wait until the CloudFront distributions are created,
  # so we have valid distribution IDs
  depends_on = [
    module.cloudfront_frontend
  ]
}

module "cloudfront_backend" {
  source = "./modules/cloudfront_backend"

  lambda_function_urls = module.lambda_module.lambda_function_urls
  acm_certificate_arns = module.acm.certificate_arns
  domain_names         = flatten(values(module.acm.domain_names))
  aliases              = var.aliases
  price_class          = var.price_class
  web_acl_id           = var.web_acl_id
  logging_config       = var.logging_config

  default_cache_behavior = {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "lambda-origin"
    forwarded_values = {
      query_string = true
      headers      = ["*"]
      cookies = {
        forward = "all"
      }
    }
    viewer_protocol_policy = "redirect-to-https"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-cloudfront"
    Project     = var.project_name
    Environment = var.environment
  }
}