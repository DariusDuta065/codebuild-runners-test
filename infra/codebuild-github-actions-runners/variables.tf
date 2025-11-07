variable "github_username" {
  description = "Your GitHub username or organization name"
  type        = string
  validation {
    condition     = length(var.github_username) > 0
    error_message = "GitHub username cannot be empty."
  }
}

variable "github_repository_url" {
  description = "GitHub repository URL for CodeBuild source (required for webhook). Use format: https://github.com/username/repo"
  type        = string
  default     = ""
  validation {
    condition     = var.github_repository_url == "" || can(regex("^https://github\\.com/", var.github_repository_url))
    error_message = "GitHub repository URL must be empty or start with https://github.com/"
  }
}

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "eu-west-1"
  validation {
    condition     = length(var.aws_region) > 0
    error_message = "AWS region cannot be empty."
  }
}

variable "project_name" {
  description = "Name for the CodeBuild project"
  type        = string
  default     = "github-runner"
  validation {
    condition     = length(var.project_name) > 0
    error_message = "Project name cannot be empty."
  }
  validation {
    condition     = length(var.project_name) <= 100
    error_message = "Project name must be 100 characters or less."
  }
}

variable "vpc_id" {
  description = "VPC ID for CodeBuild (leave empty to disable VPC)"
  type        = string
  default     = ""
  validation {
    condition     = var.vpc_id == "" || can(regex("^vpc-", var.vpc_id))
    error_message = "VPC ID must be empty or start with 'vpc-'."
  }
}

variable "build_timeout" {
  description = "Build timeout in minutes"
  type        = number
  default     = 60
  validation {
    condition     = var.build_timeout > 0 && var.build_timeout <= 480
    error_message = "Build timeout must be between 1 and 480 minutes."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "codebuild-github-runners"
    ManagedBy   = "terraform"
    Environment = "production"
  }
}

