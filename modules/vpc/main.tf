########################################
# VPC Module main.tf
########################################

locals {
  # Create a name prefix for all resources
  name_prefix = "${var.project_name}-${var.environment}"
}

# 1. Create VPC
resource "aws_vpc" "this" {
  cidr_block       = var.vpc_cidr
  tags = {
    Name       = "${local.name_prefix}-vpc"
    Project    = var.project_name
    Environment= var.environment
  }
}

# 2. Create Public Subnets
resource "aws_subnet" "public" {
  for_each = { for idx, cidr in var.public_subnets_cidr : idx => cidr }
  
  vpc_id                  = aws_vpc.this.id
  cidr_block             = each.value
  availability_zone       = element(data.aws_availability_zones.available.names, each.key)
  map_public_ip_on_launch = true
  
  tags = {
    Name       = "${local.name_prefix}-public-subnet-${each.key}"
    Project    = var.project_name
    Environment= var.environment
  }
}

# 3. Create Private Subnets
resource "aws_subnet" "private" {
  for_each = { for idx, cidr in var.private_subnets_cidr : idx => cidr }
  
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = element(data.aws_availability_zones.available.names, each.key)
  
  tags = {
    Name       = "${local.name_prefix}-private-subnet-${each.key}"
    Project    = var.project_name
    Environment= var.environment
  }
}

# 4. Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  
  tags = {
    Name       = "${local.name_prefix}-igw"
    Project    = var.project_name
    Environment= var.environment
  }
}

# 5. NAT Gateway(s)
# Here, we create a NAT Gateway for each public subnet for high availability.
resource "aws_eip" "nat" {
  for_each = aws_subnet.public

  # vpc = true
  tags = {
    Name       = "${local.name_prefix}-nat-eip-${each.key}"
    Project    = var.project_name
    Environment= var.environment
  }
}

resource "aws_nat_gateway" "this" {
  for_each          = aws_subnet.public
  allocation_id     = aws_eip.nat[each.key].id
  subnet_id         = each.value.id
  connectivity_type = "public"
  
  tags = {
    Name       = "${local.name_prefix}-nat-gw-${each.key}"
    Project    = var.project_name
    Environment= var.environment
  }
}

# 6. Route Tables and Associations

## 6.1 Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  
  tags = {
    Name       = "${local.name_prefix}-public-rt"
    Project    = var.project_name
    Environment= var.environment
  }
}

# Route to Internet Gateway
resource "aws_route" "public_to_igw" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

# Associate public subnets with the public RT
resource "aws_route_table_association" "public_association" {
  for_each        = aws_subnet.public
  subnet_id       = each.value.id
  route_table_id  = aws_route_table.public.id
}

## 6.2 Private Route Tables (one per private subnet)
resource "aws_route_table" "private" {
  for_each = aws_subnet.private
  
  vpc_id = aws_vpc.this.id
  
  tags = {
    Name       = "${local.name_prefix}-private-rt-${each.key}"
    Project    = var.project_name
    Environment= var.environment
  }
}

resource "aws_route" "private_to_nat" {
  for_each = aws_subnet.private

  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  
  # Simple approach: pick the NAT Gateway in the same AZ. 
  # For that, we match the private subnet AZ to the NAT in the same index.
  nat_gateway_id = aws_nat_gateway.this[each.key].id
}

resource "aws_route_table_association" "private_association" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

# Data source for AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Security Group for Lambda Functions
resource "aws_security_group" "lambda" {
  name        = "${local.name_prefix}-lambda-sg"
  description = "Security group for Lambda functions"
  vpc_id      = aws_vpc.this.id

  # Allow all outbound traffic (Lambda needs internet access for external APIs, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # All protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name       = "${local.name_prefix}-lambda-sg"
    Project    = var.project_name
    Environment = var.environment
  }
}