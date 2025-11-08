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

variable "build_timeout" {
  description = "Build timeout in minutes"
  type        = number
  default     = 60
  validation {
    condition     = var.build_timeout > 0 && var.build_timeout <= 480
    error_message = "Build timeout must be between 1 and 480 minutes."
  }
}

variable "github_pat_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the GitHub PAT. This should be created and managed separately using the codebuild-github-pat-secret module."
  type        = string
  validation {
    condition     = can(regex("^arn:aws:secretsmanager:", var.github_pat_secret_arn))
    error_message = "GitHub PAT secret ARN must be a valid Secrets Manager ARN."
  }
}

variable "compute_fleets" {
  description = "List of CodeBuild compute fleets. Defaults to two fleets: Linux x86_64 and Linux ARM64."
  type = list(object({
    name             = string
    architecture     = string
    minimum_capacity = number
    image            = string
    size_label       = optional(string, "small")
    vpc_config = optional(object({
      vpc_id     = string
      subnet_ids = list(string)
    }), null)
    compute_configuration = optional(object({
      vcpu_count = optional(number, 2)
      memory     = optional(number, 4)
      disk_space = optional(number, 64)
      }), {
      vcpu_count = 2
      memory     = 4
      disk_space = 64
    })
  }))
  default = [
    {
      name             = "github-runner-x86_64-small"
      architecture     = "x86_64"
      minimum_capacity = 1
      image            = "aws/codebuild/standard:7.0"
      size_label       = "small"
      compute_configuration = {
        vcpu_count = 2
        memory     = 4
        disk_space = 64
      }
    },
    {
      name             = "github-runner-arm64-small"
      architecture     = "arm64"
      minimum_capacity = 1
      image            = "aws/codebuild/standard:7.0"
      size_label       = "small"
      compute_configuration = {
        vcpu_count = 2
        memory     = 4
        disk_space = 64
      }
    }
  ]
  validation {
    condition     = alltrue([for fleet in var.compute_fleets : contains(["x86_64", "arm64"], fleet.architecture)])
    error_message = "Architecture must be 'x86_64' or 'arm64'."
  }
  validation {
    condition     = alltrue([for fleet in var.compute_fleets : fleet.minimum_capacity > 0 && fleet.minimum_capacity <= 100])
    error_message = "Minimum capacity must be between 1 and 100."
  }
  validation {
    condition     = alltrue([for fleet in var.compute_fleets : fleet.compute_configuration.vcpu_count >= 1 && fleet.compute_configuration.vcpu_count <= 4])
    error_message = "vCPU count must be between 1 and 4."
  }
  validation {
    condition     = alltrue([for fleet in var.compute_fleets : fleet.compute_configuration.memory >= 2 && fleet.compute_configuration.memory <= 8])
    error_message = "Memory must be between 2 and 8 GB."
  }
  validation {
    condition     = alltrue([for fleet in var.compute_fleets : fleet.compute_configuration.disk_space == 64])
    error_message = "Disk space must be 64 GB."
  }
  validation {
    condition     = alltrue([for fleet in var.compute_fleets : length(fleet.image) > 0])
    error_message = "Image field is required and cannot be empty."
  }
  validation {
    condition     = alltrue([for fleet in var.compute_fleets : length(fleet.name) > 0])
    error_message = "Name field is required and cannot be empty."
  }
}

