
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

# Get GitHub's OIDC certificate thumbprint
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# Create OIDC Provider for GitHub Actions
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
  tags            = var.tags
}

# Create IAM role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  name = var.role_name

  # Trust policy for GitHub OIDC
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # RESTRICT TO YOUR GITHUB ACCOUNT REPOS
            "token.actions.githubusercontent.com:sub" = [
              "repo:${var.github_username}/*",
            ]
          }
        }
      }
    ]
  })

  description          = var.role_description
  tags                 = var.tags
  max_session_duration = var.max_session_duration
}

# Optionally attach a managed policy (example with read-only access)
resource "aws_iam_role_policy_attachment" "read_only_access" {
  count = length(var.attached_policy_arns)

  role       = aws_iam_role.github_actions.name
  policy_arn = var.attached_policy_arns[count.index]
}

# Create an inline policy for full ECR permissions
resource "aws_iam_policy" "ecr_full_access" {
  name        = "${var.role_name}-ecr-full-access"
  description = "Full ECR access permissions for GitHub Actions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:*",
        ]
        Resource = "*"
      }
    ]
  })
}

# Create an inline policy for full ECS permissions
resource "aws_iam_policy" "ecs_full_access" {
  name        = "${var.role_name}-ecs-full-access"
  description = "Full ECS access permissions for GitHub Actions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:*",
        ]
        Resource = "*"
      }
    ]
  })
}

# Create an inline policy for full Lambda permissions
resource "aws_iam_policy" "lambda_full_access" {
  name        = "${var.role_name}-lambda-full-access"
  description = "Full Lambda access permissions for GitHub Actions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:*",
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach the policies to the role
resource "aws_iam_role_policy_attachment" "ecr_policy_attachment" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.ecr_full_access.arn
}

resource "aws_iam_role_policy_attachment" "ecs_policy_attachment" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.ecs_full_access.arn
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.lambda_full_access.arn
}

# Create an output with the role ARN
output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions IAM role"
  value       = aws_iam_role.github_actions.arn
}

# Create an output with the OIDC provider URL
output "github_oidc_provider_url" {
  description = "URL of the GitHub OIDC provider"
  value       = aws_iam_openid_connect_provider.github.url
}

# Create an output with instructions for GitHub
output "github_actions_setup_instructions" {
  description = "Instructions for setting up GitHub Actions to use this role"
  value       = <<EOF
To use this IAM role in your GitHub Actions workflow, add the following to your workflow YAML:

- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${aws_iam_role.github_actions.arn}
    aws-region: ${var.aws_region}

Make sure to add the following repository secret in your GitHub repository:
- AWS_ROLE_ARN: ${aws_iam_role.github_actions.arn}

This role is restricted to repos in the GitHub account: ${var.github_username}
EOF
}
