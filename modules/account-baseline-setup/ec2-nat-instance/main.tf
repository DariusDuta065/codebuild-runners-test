terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  backend "s3" {
    bucket       = "terraform-state-590624982938"
    key          = "ec2-nat-instance/terraform.tfstate"
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
      Project     = "ec2-nat-instance"
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

# Data source for existing private subnets (from private-subnets-nat-gateway module)
data "aws_subnets" "existing_private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name = "tag:Name"
    values = [
      "private-subnets-nat-private-subnet-1",
      "private-subnets-nat-private-subnet-2",
      "private-subnets-nat-private-subnet-3"
    ]
  }
}

# Get details of existing private subnets
data "aws_subnet" "existing_private" {
  for_each = toset(data.aws_subnets.existing_private.ids)
  id       = each.value
}

# Data source for existing private route table (from private-subnets-nat-gateway module)
data "aws_route_table" "existing_private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "tag:Name"
    values = ["private-subnets-nat-private-rt"]
  }
}

# Get the first public subnet for NAT instance placement
locals {
  public_subnet_ids = data.aws_subnets.public.ids
  # Use first public subnet for NAT instance
  nat_instance_subnet_id = length(local.public_subnet_ids) > 0 ? local.public_subnet_ids[0] : null
}

# IAM Role for SSM Session Manager
resource "aws_iam_role" "fck_nat_ssm" {
  name = "${var.name_prefix}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.name_prefix}-ssm-role"
  }
}

# Attach AWS managed policy for SSM
resource "aws_iam_role_policy_attachment" "fck_nat_ssm" {
  role       = aws_iam_role.fck_nat_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "fck_nat_ssm" {
  name = "${var.name_prefix}-ssm-profile"
  role = aws_iam_role.fck_nat_ssm.name

  tags = {
    Name = "${var.name_prefix}-ssm-profile"
  }
}

# Data source for fck-nat AMI
data "aws_ami" "fck_nat" {
  filter {
    name   = "name"
    values = ["fck-nat-al2023-*"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  owners      = ["568608671756"]
  most_recent = true
}

# Get default security group for VPC
data "aws_security_group" "default" {
  name   = "default"
  vpc_id = data.aws_vpc.default.id
}

# Network interface for fck-nat instance
resource "aws_network_interface" "fck_nat" {
  subnet_id         = local.nat_instance_subnet_id
  security_groups   = [data.aws_security_group.default.id]
  source_dest_check = false

  tags = {
    Name = "${var.name_prefix}-eni"
  }
}

# Elastic IP for the NAT instance
resource "aws_eip" "fck_nat" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.fck_nat.id
  associate_with_private_ip = aws_network_interface.fck_nat.private_ip

  tags = {
    Name = "${var.name_prefix}-eip"
  }

  depends_on = [aws_instance.fck_nat]
}

# fck-nat EC2 instance
resource "aws_instance" "fck_nat" {
  ami           = data.aws_ami.fck_nat.id
  instance_type = "t4g.nano"

  iam_instance_profile = aws_iam_instance_profile.fck_nat_ssm.name

  network_interface {
    network_interface_id = aws_network_interface.fck_nat.id
    device_index         = 0
  }

  tags = {
    Name = var.name_prefix
  }
}

# Route in private route table to use NAT instance
resource "aws_route" "private_to_nat" {
  route_table_id         = data.aws_route_table.existing_private.id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_network_interface.fck_nat.id
}

