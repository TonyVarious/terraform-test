locals {
  bucket_name = "${var.project_name}-${var.environment}-web1"
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "this" {
  bucket = local.bucket_name

  tags = {
    Name        = local.bucket_name
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id
  
  block_public_acls       = var.block_public_access
  block_public_policy     = var.block_public_access
  ignore_public_acls      = var.block_public_access
  restrict_public_buckets = var.block_public_access
}

# Build a bucket policy allowing multiple CloudFront distributions to read the bucket.
# Each distribution ID => one policy statement referencing its ARN.
# Only attach if cloudfront_distribution_ids is non-empty.
data "aws_iam_policy_document" "this" {
  statement {
    sid     = "DenyAllExceptListed"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      "arn:aws:s3:::${local.bucket_name}",
      "arn:aws:s3:::${local.bucket_name}/*"
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

  dynamic "statement" {
    for_each = var.cloudfront_distribution_ids
    content {
      sid     = "AllowCF-${statement.value}"
      effect  = "Allow"
      actions = ["s3:GetObject"]
      resources = [
        "arn:aws:s3:::${local.bucket_name}/*"
      ]
      principals {
        type        = "Service"
        identifiers = ["cloudfront.amazonaws.com"]
      }

      condition {
        test     = "StringEquals"
        variable = "AWS:SourceArn"
        values   = [    
          "arn:aws:cloudfront::${var.waf_account_id != "" ? var.waf_account_id : data.aws_caller_identity.current.account_id}:distribution/${statement.value}"
        ]
      }
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.this.json

  # Only create if we actually have CloudFront distributions or we want a deny statement for https
  count  = length(var.cloudfront_distribution_ids) > 0 ? 1 : 1
  
  lifecycle {
    ignore_changes = [policy]
  }
  # If you never want a policy unless there's CF, you can do count = length(...) > 0 ? 1 : 0
}

