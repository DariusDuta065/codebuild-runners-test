variable "aws_region" {
  description = "AWS region where the secret will be created"
  type        = string
  default     = "eu-west-1"
  validation {
    condition     = length(var.aws_region) > 0
    error_message = "AWS region cannot be empty."
  }
}

variable "secret_name" {
  description = "Base name for the secret (will be suffixed with '-github-pat')"
  type        = string
  default     = "github-runner"
  validation {
    condition     = length(var.secret_name) > 0
    error_message = "Secret name cannot be empty."
  }
}

