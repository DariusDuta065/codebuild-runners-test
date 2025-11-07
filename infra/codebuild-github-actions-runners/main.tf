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
    key          = "codebuild-github-actions-runners/terraform.tfstate"
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
      Project     = "codebuild-github-runners"
      ManagedBy   = "terraform"
      Environment = "production"
    }
  }
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
        Resource = var.github_pat_secret_arn
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeDhcpOptions",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeNetworkInterfaces"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterfacePermission"
        ]
        Resource = "arn:aws:ec2:${var.aws_region}:*:network-interface/*"
        Condition = {
          StringLike = {
            "ec2:Subnet" = [
              "arn:aws:ec2:${var.aws_region}:*:subnet/*"
            ]
            "ec2:AuthorizedService" = "codebuild.amazonaws.com"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents"
        ]
        Resource = [
          "arn:aws:logs:${var.aws_region}:*:log-group:/aws/codebuild/${var.project_name}*",
          "arn:aws:logs:${var.aws_region}:*:log-group:/aws/codebuild/${var.project_name}*:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild" {
  role       = aws_iam_role.codebuild.name
  policy_arn = aws_iam_policy.codebuild.arn
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
    # Privileged mode is required when running Docker-in-Docker inside a VPC
    privileged_mode = var.vpc_id != "" ? true : false

    environment_variable {
      name  = "GITHUB_PAT_SECRET_ARN"
      value = var.github_pat_secret_arn
    }
  }

  source {
    type            = "GITHUB"
    location        = var.github_repository_url != "" ? var.github_repository_url : "https://github.com/${var.github_username}/codebuild-runners-test"
    git_clone_depth = 1

    # Note: Auth will be configured after GitHub PAT secret is updated with actual token
    auth {
      type     = "SECRETS_MANAGER"
      resource = var.github_pat_secret_arn
    }
  }

  dynamic "vpc_config" {
    for_each = var.vpc_id != "" ? [1] : []
    content {
      vpc_id             = data.aws_vpc.main[0].id
      subnets            = local.codebuild_subnet_ids
      security_group_ids = [aws_security_group.codebuild[0].id]
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${var.project_name}"
      stream_name = "build-log"
    }
  }
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
