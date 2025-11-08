terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region  = "eu-west-1"
  profile = "default"
}

# Get VPC
data "aws_vpc" "default" {
  default = true
}

# Get private subnets
data "aws_subnets" "private" {
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

# IAM Role for SSM
resource "aws_iam_role" "test_instance_ssm" {
  name = "test-instance-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "test_instance_ssm" {
  role       = aws_iam_role.test_instance_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "test_instance_ssm" {
  name = "test-instance-ssm-profile"
  role = aws_iam_role.test_instance_ssm.name
}

# Get Amazon Linux 2023 ARM64 AMI (full, not minimal)
# Standard AMI pattern: al2023-ami-2023.*-kernel-*-arm64 (excludes minimal)
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-kernel-*-arm64"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }
}

# Test EC2 instance in private subnet
resource "aws_instance" "test" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t4g.nano"
  subnet_id     = data.aws_subnets.private.ids[0]

  iam_instance_profile = aws_iam_instance_profile.test_instance_ssm.name

  tags = {
    Name = "test-instance-private-subnet"
  }
}

