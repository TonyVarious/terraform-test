# project_variables = {
#   project_name = "chuck-fanduel"
#   environment = "dev"
#   partner = null
# }

aws_region           = "us-east-1"
vpc_cidr             = "10.1.0.0/16"
public_subnets_cidr  = ["10.1.2.0/24", "10.1.3.0/24"]
private_subnets_cidr = ["10.1.0.0/24", "10.1.1.0/24"]
project_name         = "chuck-fanduel"
environment          = "dev"
subenv = ["qa", "uat"]

dynamodb_tables = [
  {
    name                = "ActiveSessionCounter"
    partition_key       = "CounterName"
  },
  {
    name                = "Chats"
    partition_key       = "sessionId"
  },
    {
    name                = "ChatSessions"
    partition_key       = "sessionId"
  },
    {
    name                = "request_logs"
    partition_key       = "id"
  },
    {
    name                = "WaitingQueue"
    partition_key       = "sessionId"
  }
]

acm_certificates = [
  {
    subenv             = "qa"
    domain             = "chuck.ninetwothree.co"
    subdomains         = ["app", "api"]
    validation_enabled = true
    hosted_zone_id     = "Z06323243KV1N5LK0KG2Z"  # The Hosted Zone for qa.chuck.example.com
  },
  {
    subenv             = "uat"
    domain             = "chuck.ninetwothree.co"
    subdomains         = ["app", "api"]
    validation_enabled = true
    hosted_zone_id     = "Z06310783JBNJR2NY8TKT" # The Hosted Zone for uat.chuck.example.com
  }
]

waf_arn = "arn:aws:wafv2:us-east-1:442042513173:global/webacl/waf-test/2595c9cc-ac1d-4f32-a534-800cd3c2858a"