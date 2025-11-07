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
    key          = "codebuild-github-pat-secret/terraform.tfstate"
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

# AWS Secrets Manager Secret for GitHub PAT
# IMPORTANT: After creating this secret, you must manually populate it with your actual GitHub PAT
# The secret must be in JSON format:
# {
#   "ServerType": "GITHUB",
#   "AuthType": "PERSONAL_ACCESS_TOKEN",
#   "Token": "your-actual-token-here"
# }
resource "aws_secretsmanager_secret" "github_pat" {
  name        = "${var.secret_name}-github-pat"
  description = "GitHub Personal Access Token for CodeBuild GitHub Actions runner. Secret must be in JSON format: {\"ServerType\":\"GITHUB\",\"AuthType\":\"PERSONAL_ACCESS_TOKEN\",\"Token\":\"your-token-here\"}"
}

# Initial placeholder version - MUST be updated manually with actual token
resource "aws_secretsmanager_secret_version" "github_pat" {
  secret_id = aws_secretsmanager_secret.github_pat.id
  secret_string = jsonencode({
    ServerType = "GITHUB"
    AuthType   = "PERSONAL_ACCESS_TOKEN"
    Token      = "ghp_PLACEHOLDER_REPLACE_WITH_ACTUAL_TOKEN"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

