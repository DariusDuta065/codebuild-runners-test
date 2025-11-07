variable "github_username" {
  description = "Your GitHub username or organization name to restrict access to"
  type        = string
  validation {
    condition     = length(var.github_username) > 0
    error_message = "GitHub username cannot be empty."
  }
}

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
  validation {
    condition     = length(var.aws_region) > 0
    error_message = "AWS region cannot be empty."
  }
}

variable "role_name" {
  description = "Name for the IAM role"
  type        = string
  default     = "github-actions-oidc-role"
  validation {
    condition     = length(var.role_name) > 0
    error_message = "Role name cannot be empty."
  }
  validation {
    condition     = length(var.role_name) <= 64
    error_message = "Role name must be 64 characters or less."
  }
}

variable "role_description" {
  description = "Description for the IAM role"
  type        = string
  default     = "IAM role for GitHub Actions OIDC authentication"
}

variable "max_session_duration" {
  description = "Maximum session duration for the role in seconds (3600-43200)"
  type        = number
  default     = 3600
  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "Max session duration must be between 3600 and 43200 seconds."
  }
}

variable "attached_policy_arns" {
  description = "List of IAM policy ARNs to attach to the role"
  type        = list(string)
  default = [
    # Example: AWS managed policy for read-only S3 access
    # "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
  ]
}
