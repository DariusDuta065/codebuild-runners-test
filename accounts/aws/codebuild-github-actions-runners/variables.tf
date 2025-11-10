variable "codebuild_location" {
  description = "Target for CodeBuild: provide either the GitHub repository URL (https://github.com/owner/repo) or the GitHub organization name."
  type        = string
  validation {
    condition     = length(var.codebuild_location) > 0
    error_message = "codebuild_location is required and cannot be empty."
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

variable "codeconnections_connection_arn" {
  description = "ARN of the AWS CodeConnections connection for GitHub."
  type        = string
  validation {
    condition     = var.codeconnections_connection_arn == "" || can(regex("^arn:aws:codeconnections:", var.codeconnections_connection_arn))
    error_message = "CodeConnections connection ARN must be empty or a valid CodeConnections ARN."
  }
}

variable "runners" {
  description = "List of CodeBuild runners (mapping to CodeBuild build projects). Supports both Compute Fleets (with reserved capacity) and On-Demand projects. Defaults to one fleet runner: Linux x86_64."
  type = list(object({
    name                   = string
    compute_type           = string # "FLEET" or "ON_DEMAND"
    architecture           = string
    image                  = string           # See: https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-available.html
    minimum_capacity       = optional(number) # Required only for compute_type = "FLEET"
    on_demand_compute_type = optional(string) # Required only for compute_type = "ON_DEMAND". See: https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-compute-types.html

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
      compute_type     = "FLEET"
      architecture     = "x86_64"
      minimum_capacity = 1
      image            = "aws/codebuild/amazonlinux-x86_64-standard:5.0"
      compute_configuration = {
        vcpu_count = 2
        memory     = 4
        disk_space = 64
      }
    }
  ]
  validation {
    condition     = alltrue([for runner in var.runners : contains(["FLEET", "ON_DEMAND"], runner.compute_type)])
    error_message = "compute_type must be 'FLEET' or 'ON_DEMAND'."
  }
  validation {
    condition     = alltrue([for runner in var.runners : contains(["x86_64", "arm64"], runner.architecture)])
    error_message = "Architecture must be 'x86_64' or 'arm64'."
  }
  validation {
    condition = alltrue([
      for runner in var.runners : runner.compute_type != "FLEET" || (runner.minimum_capacity != null && runner.minimum_capacity > 0 && runner.minimum_capacity <= 100)
    ])
    error_message = "minimum_capacity is required for FLEET compute_type and must be between 1 and 100."
  }
  validation {
    condition     = alltrue([for runner in var.runners : runner.compute_configuration.vcpu_count >= 1 && runner.compute_configuration.vcpu_count <= 4])
    error_message = "vCPU count must be between 1 and 4."
  }
  validation {
    condition     = alltrue([for runner in var.runners : runner.compute_configuration.memory >= 2 && runner.compute_configuration.memory <= 8])
    error_message = "Memory must be between 2 and 8 GB."
  }
  validation {
    condition     = alltrue([for runner in var.runners : runner.compute_configuration.disk_space == 64])
    error_message = "Disk space must be 64 GB."
  }
  validation {
    condition     = alltrue([for runner in var.runners : length(runner.image) > 0])
    error_message = "Image field is required and cannot be empty."
  }
  validation {
    condition     = alltrue([for runner in var.runners : length(runner.name) > 0])
    error_message = "Name field is required and cannot be empty."
  }
  validation {
    condition = alltrue([
      for runner in var.runners : runner.compute_type != "ON_DEMAND" || (
        runner.on_demand_compute_type != null && runner.on_demand_compute_type != "" &&
        contains([
          "BUILD_GENERAL1_SMALL",
          "BUILD_GENERAL1_MEDIUM",
          "BUILD_GENERAL1_LARGE",
          "BUILD_GENERAL1_XLARGE",
          "BUILD_GENERAL1_2XLARGE",
          "BUILD_LAMBDA_1GB",
          "BUILD_LAMBDA_2GB",
          "BUILD_LAMBDA_4GB",
          "BUILD_LAMBDA_8GB",
          "BUILD_LAMBDA_10GB",
          "CUSTOM_INSTANCE_TYPE"
        ], runner.on_demand_compute_type)
      )
    ])
    error_message = "on_demand_compute_type is required for ON_DEMAND compute_type and must be one of: BUILD_GENERAL1_SMALL, BUILD_GENERAL1_MEDIUM, BUILD_GENERAL1_LARGE, BUILD_GENERAL1_XLARGE, BUILD_GENERAL1_2XLARGE, BUILD_LAMBDA_1GB, BUILD_LAMBDA_2GB, BUILD_LAMBDA_4GB, BUILD_LAMBDA_8GB, BUILD_LAMBDA_10GB, CUSTOM_INSTANCE_TYPE"
  }
}
