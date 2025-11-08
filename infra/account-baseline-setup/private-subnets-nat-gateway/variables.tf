variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "eu-west-1"
  validation {
    condition     = length(var.aws_region) > 0
    error_message = "AWS region cannot be empty."
  }
}

variable "name_prefix" {
  description = "Prefix for resource naming"
  type        = string
  default     = "private-subnets-nat"
  validation {
    condition     = length(var.name_prefix) > 0
    error_message = "Name prefix cannot be empty."
  }
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for the 3 private subnets"
  type        = list(string)
  validation {
    condition     = length(var.private_subnet_cidrs) == 3
    error_message = "Exactly 3 CIDR blocks must be provided for private subnets."
  }
  validation {
    condition = alltrue([
      for cidr in var.private_subnet_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "All CIDR blocks must be valid."
  }
}

variable "availability_zones" {
  description = "List of availability zones for private subnets. If not provided, will use zones from existing public subnets."
  type        = list(string)
  default     = []
  validation {
    condition     = length(var.availability_zones) == 0 || length(var.availability_zones) >= 3
    error_message = "If provided, availability_zones must have at least 3 zones."
  }
}

