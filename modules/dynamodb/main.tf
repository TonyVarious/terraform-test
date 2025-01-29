########################################
# DynamoDB Module main.tf
########################################

locals {
  name_prefix = "${var.project_name}"
}

# Create multiple DynamoDB tables in a loop
resource "aws_dynamodb_table" "this" {
  # Use 'for_each' keyed by table name
  for_each = { for table in var.dynamodb_tables : table.name => table }

  name         = "${local.name_prefix}-${each.value.name}"
  billing_mode = each.value.billing_mode # e.g., "PAY_PER_REQUEST" (on-demand) or "PROVISIONED"

  # Simple schema: single partition key of type "S" (string)
  hash_key = each.value.partition_key
  
  attribute {
    name = each.value.partition_key
    type = "S"
  }

  point_in_time_recovery {
    enabled = each.value.pitr_enabled
  }

  deletion_protection_enabled = each.value.deletion_protection

  # You can optionally add read/write capacity here if using "PROVISIONED"
  # read_capacity  = 1
  # write_capacity = 1

  tags = {
    Name        = "${local.name_prefix}-${each.value.name}"
    Project     = var.project_name
    Environment = var.environment
  }
}
