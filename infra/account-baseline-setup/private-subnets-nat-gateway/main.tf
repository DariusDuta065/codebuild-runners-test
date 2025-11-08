terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket       = "terraform-state-590624982938"
    key          = "private-subnets-nat-gateway/terraform.tfstate"
    region       = "eu-west-1"
    use_lockfile = true
  }
}

# Configure the AWS Provider
provider "aws" {
  region  = var.aws_region
  profile = "default"

  default_tags {
    tags = {
      Project     = "private-subnets-nat-gateway"
      ManagedBy   = "terraform"
      Environment = "production"
    }
  }
}

# Data source for default VPC
data "aws_vpc" "default" {
  default = true
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Data source for existing public subnets (default subnets)
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

# Get details of public subnets
data "aws_subnet" "public" {
  for_each = toset(data.aws_subnets.public.ids)
  id       = each.value
}

locals {
  # Get availability zones from public subnets (sorted and unique)
  public_subnet_azs = sort(distinct([
    for subnet in data.aws_subnet.public : subnet.availability_zone
  ]))

  # Use provided availability zones, or from public subnets, or from available zones data source
  availability_zones = length(var.availability_zones) > 0 ? var.availability_zones : (
    length(local.public_subnet_azs) >= 3 ? local.public_subnet_azs : data.aws_availability_zones.available.names
  )

  # Ensure we have exactly 3 availability zones
  azs = slice(local.availability_zones, 0, min(3, length(local.availability_zones)))
}

# Create 3 private subnets
resource "aws_subnet" "private" {
  count             = 3
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]

  tags = {
    Name = "${var.name_prefix}-private-subnet-${count.index + 1}"
    Type = "private"
  }
}

# Route table for private subnets
# Note: Route to NAT instance should be added separately
resource "aws_route_table" "private" {
  vpc_id = data.aws_vpc.default.id

  tags = {
    Name = "${var.name_prefix}-private-rt"
    Type = "private"
  }
}

# Associate private subnets with private route table
resource "aws_route_table_association" "private" {
  count          = 3
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

