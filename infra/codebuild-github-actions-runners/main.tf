terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region  = var.aws_region
  profile = "default"
}

# AWS Secrets Manager Secret for GitHub PAT
resource "aws_secretsmanager_secret" "github_pat" {
  name        = "${var.project_name}-github-pat"
  description = "GitHub Personal Access Token for CodeBuild GitHub Actions runner. Secret must be in JSON format: {\"ServerType\":\"GITHUB\",\"AuthType\":\"PERSONAL_ACCESS_TOKEN\",\"Token\":\"your-token-here\"}"
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "github_pat" {
  secret_id = aws_secretsmanager_secret.github_pat.id
  secret_string = jsonencode({
    ServerType = "GITHUB"
    AuthType   = "PERSONAL_ACCESS_TOKEN"
    Token      = "ghp_..."
  })
}

# IAM Role for CodeBuild
resource "aws_iam_role" "codebuild" {
  name = "${var.project_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for CodeBuild
resource "aws_iam_policy" "codebuild" {
  name        = "${var.project_name}-policy"
  description = "Policy for CodeBuild GitHub Actions runner"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.github_pat.arn
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeNetworkInterfaces"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:log-group:/aws/codebuild/${var.project_name}*"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "codebuild" {
  role       = aws_iam_role.codebuild.name
  policy_arn = aws_iam_policy.codebuild.arn
}

# VPC Configuration
data "aws_vpc" "main" {
  id = var.vpc_id
}

data "aws_subnets" "main" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
}

# Security Group for CodeBuild
resource "aws_security_group" "codebuild" {
  name        = "${var.project_name}-sg"
  description = "Security group for CodeBuild GitHub Actions runners"
  vpc_id      = data.aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-sg"
  })
}

# CodeBuild Project
resource "aws_codebuild_project" "github_runner" {
  name          = var.project_name
  description   = "Self-hosted GitHub Actions runner using AWS CodeBuild"
  build_timeout = var.build_timeout
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "GITHUB_PAT_SECRET_ARN"
      value = aws_secretsmanager_secret.github_pat.arn
    }
  }

  source {
    type            = "GITHUB"
    location        = var.github_repository_url != "" ? var.github_repository_url : "https://github.com/${var.github_username}/codebuild-runners-test"
    git_clone_depth = 1

    # Note: Auth will be configured after GitHub PAT secret is updated with actual token
    auth {
      type     = "SECRETS_MANAGER"
      resource = aws_secretsmanager_secret.github_pat.arn
    }
  }

  vpc_config {
    vpc_id             = data.aws_vpc.main.id
    subnets            = data.aws_subnets.main.ids
    security_group_ids = [aws_security_group.codebuild.id]
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${var.project_name}"
      stream_name = "build-log"
    }
  }

  tags = var.tags
}

# CodeBuild Webhook for GitHub Actions
# Note: Webhook requires GitHub PAT to be configured in the source auth first
resource "aws_codebuild_webhook" "github" {
  project_name = aws_codebuild_project.github_runner.name

  filter_group {
    filter {
      type    = "EVENT"
      pattern = "WORKFLOW_JOB_QUEUED"
    }
  }
}
