# VPC Configuration (only if vpc_id is provided)
data "aws_vpc" "main" {
  count = var.vpc_id != "" ? 1 : 0
  id    = var.vpc_id
}

data "aws_subnets" "main" {
  count = var.vpc_id != "" ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main[0].id]
  }
}

# Use provided subnet IDs, or all subnets in VPC
locals {
  codebuild_subnet_ids = length(var.subnet_ids) > 0 ? var.subnet_ids : (var.vpc_id != "" ? data.aws_subnets.main[0].ids : [])
}

# Security Group for CodeBuild (only if vpc_id is provided)
# CodeBuild initiates all connections, so no ingress rules are needed
# Egress rules allow necessary outbound traffic for builds
resource "aws_security_group" "codebuild" {
  count       = var.vpc_id != "" ? 1 : 0
  name        = "${var.project_name}-sg"
  description = "Security group for CodeBuild GitHub Actions runners"
  vpc_id      = data.aws_vpc.main[0].id

  # No ingress rules - CodeBuild initiates all connections outbound

  # HTTPS egress for GitHub API, AWS APIs, and package repositories
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS outbound for GitHub API, AWS APIs, and package repositories"
  }

  # HTTP egress for package managers and redirects
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP outbound for package managers"
  }

  # DNS egress (UDP) for DNS resolution
  # Note: 0.0.0.0/0 covers all DNS servers including VPC DNS resolver
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow DNS outbound (UDP) for DNS resolution"
  }

  # DNS egress (TCP) for DNS resolution fallback
  # Note: 0.0.0.0/0 covers all DNS servers including VPC DNS resolver
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow DNS outbound (TCP) for DNS resolution fallback"
  }

  # NTP egress for time synchronization
  egress {
    from_port   = 123
    to_port     = 123
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow NTP outbound for time synchronization"
  }

  tags = {
    Name = "${var.project_name}-sg"
  }
}

