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

