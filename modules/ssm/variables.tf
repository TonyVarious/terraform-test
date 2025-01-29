variable "project_name" {
  type        = string
  description = "Project name for tagging."
}

variable "environment" {
  type        = string
  description = "Environment (e.g., dev or prod) for tagging."
}

variable "ssm_parameters" {
  type = map(string)
  description = "Map of SSM parameter keys to values."
  default = {}
}

variable "parameter_type" {
  type        = string
  description = "Type of SSM parameters: String, SecureString, etc."
  default     = "String"
}
