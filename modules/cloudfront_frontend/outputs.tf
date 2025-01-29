output "distribution_ids" {
  description = "Map of subenv => distribution IDs."
  value = {
    for subenv, dist in aws_cloudfront_distribution.this :
    subenv => dist.id
  }
}

output "distribution_domain_names" {
  description = "Map of subenv => distribution domain names."
  value = {
    for subenv, dist in aws_cloudfront_distribution.this :
    subenv => dist.domain_name
  }
}
