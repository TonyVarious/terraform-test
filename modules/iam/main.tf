########################################
# IAM Module main.tf
########################################

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  # If lambda_role_name is empty, default to a generated name
  lambda_role_name = var.lambda_role_name != "" ? var.lambda_role_name : "${local.name_prefix}-lambda-exec-role"
}

resource "aws_iam_role" "lambda_execution_role" {
  name               = local.lambda_role_name
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = {
    Name        = local.lambda_role_name
    Project     = var.project_name
    Environment = var.environment
  }
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Create an inline policy for Lambda's permissions
# For demonstration, we'll allow:
#  - DynamoDB (all tables) if dynamodb_access=true
#  - SSM parameter read for the specified paths
#  - CloudWatch logs
data "aws_iam_policy_document" "lambda_policy" {
  # CloudWatch Logs access
  statement {
    effect    = "Allow"
    actions   = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["*"]
  }

  # DynamoDB (read/write all tables) if enabled
  dynamic "statement" {
    for_each = var.dynamodb_access ? ["enabled"] : []
    content {
      effect    = "Allow"
      actions   = ["dynamodb:*"]
      resources = ["*"]
    }
  }

  # SSM read for all parameter paths in a single statement
  # Each entry in var.ssm_parameter_paths becomes a resource "arn:aws:ssm:*:*:parameter{path}*"
  statement {
    effect    = "Allow"
    actions   = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
      "ssm:DescribeParameters"
    ]
    resources = [
      for path in var.ssm_parameter_paths :
      "arn:aws:ssm:*:*:parameter${path}*"
    ]
  }
}


resource "aws_iam_policy" "lambda_inline_policy" {
  name        = "${local.name_prefix}-lambda-policy"
  policy      = data.aws_iam_policy_document.lambda_policy.json

  tags = {
    Name        = "${local.name_prefix}-lambda-policy"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "attach_lambda_inline_policy" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_inline_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

