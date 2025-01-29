########################################
# SSM Module main.tf
########################################

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# We'll loop through the map and create each parameter
resource "aws_ssm_parameter" "parameters" {
  for_each = var.ssm_parameters

  name        = each.key
  type        = var.parameter_type
  value       = each.value
  description = "Parameter for ${local.name_prefix}"

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}
