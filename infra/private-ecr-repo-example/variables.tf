variable "aws_region" {
  description = "AWS region for the ECR repository"
  type        = string
  default     = "eu-west-1"
}

variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "200mb-image"
}
