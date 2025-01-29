########################################
# VPC Module Variables
########################################

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC."
}

variable "public_subnets_cidr" {
  type        = list(string)
  description = "List of CIDR blocks for public subnets."
}

variable "private_subnets_cidr" {
  type        = list(string)
  description = "List of CIDR blocks for private subnets."
}

variable "project_name" {
  type        = string
  description = "Project name used for tagging/naming."
}

variable "environment" {
  type        = string
  description = "Environment name (dev, prod) used for tagging/naming."
}
