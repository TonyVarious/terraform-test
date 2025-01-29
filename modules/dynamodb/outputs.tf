output "dynamodb_table_ids" {
  description = "Map of DynamoDB table IDs keyed by table name."
  value = {
    for name, tbl in aws_dynamodb_table.this :
    name => tbl.id
  }
}

output "dynamodb_table_names" {
  description = "Map of DynamoDB table names keyed by table name."
  value = {
    for name, tbl in aws_dynamodb_table.this :
    name => tbl.name
  }
}

output "dynamodb_table_arns" {
  description = "Map of DynamoDB table ARNs keyed by table name."
  value = {
    for name, tbl in aws_dynamodb_table.this :
    name => tbl.arn
  }
}
