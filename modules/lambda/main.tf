########################################
# Lambda With Layer Module
########################################

locals {
  name_prefix = "${var.project_name}-${var.subenv}"
}

#############################
# 1) Create the Common Layer
#############################
resource "aws_lambda_layer_version" "common_layer" {
  layer_name          = "${local.name_prefix}-common-layer"
  description         = var.layer_description
  compatible_runtimes = [var.runtime]

  s3_bucket = var.layer_s3_bucket
  s3_key    = var.layer_s3_key
}

########################################
# 2) Create Multiple Lambda Functions
########################################
resource "aws_lambda_function" "functions" {
  for_each = { for f in var.lambda_definitions : f.name => f }

  function_name = "${each.value.name}"
  role          = var.lambda_execution_role_arn
  runtime       = var.runtime
  handler       = each.value.handler
  memory_size   = each.value.memory_size
  timeout       = each.value.timeout

  # Code for the functions
  s3_bucket = var.source_code_s3_bucket
  s3_key    = var.source_code_s3_key

  # Attach the common layer
  layers = [
    aws_lambda_layer_version.common_layer.arn
  ]

  # If functions need to run in a private VPC, you can add:
  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = var.security_group_ids
  }

  tags = {
    Name        = "${local.name_prefix}-${each.value.name}"
    Project     = var.project_name
    Environment = var.environment
  }
}

########################################################
# 3) Optionally Create Lambda Function URLs (If Desired)
########################################################
resource "aws_lambda_function_url" "function_urls" {
  for_each           = var.enable_function_urls ? aws_lambda_function.functions : {}
  function_name      = each.value.arn
  authorization_type = "NONE"

  depends_on = [aws_lambda_function.functions]
}

# Restrict function URLs to CloudFront only if function URLs are enabled
resource "aws_lambda_permission" "allow_cf_invoke" {
  for_each = var.enable_function_urls ? aws_lambda_function.functions : {}
  
  statement_id           = "AllowCFPrincipal"
  action                 = "lambda:InvokeFunctionUrl"
  principal              = "cloudfront.amazonaws.com"
  function_name          = each.value.function_name
  function_url_auth_type = "NONE"
}

