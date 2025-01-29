########################################
# VPC Module Outputs
########################################

output "vpc_id" {
  description = "The ID of the VPC."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "List of IDs of the public subnets."
  value       = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  description = "List of IDs of the private subnets."
  value       = [for s in aws_subnet.private : s.id]
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs, one per public subnet."
  value       = [for n in aws_nat_gateway.this : n.id]
}

output "lambda_security_group_id" {
  description = "Security group ID for Lambda functions."
  value       = aws_security_group.lambda.id
}