# Security groups for CodeBuild projects with VPC (both on-demand and fleet)
resource "aws_security_group" "codebuild" {
  for_each = {
    for idx, runner in var.runners : idx => runner
    if runner.vpc_config != null
  }

  name        = "${each.value.name}-sg"
  description = "Security group for CodeBuild project ${each.value.name}"
  vpc_id      = each.value.vpc_config.vpc_id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "DNS UDP"
  }

  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "DNS TCP"
  }

  egress {
    from_port   = 123
    to_port     = 123
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "NTP"
  }

  tags = {
    Name = "${each.value.name}-sg"
  }
}

# CodeBuild Projects - one per runner (fleet or on-demand)
resource "aws_codebuild_project" "github_runner" {
  for_each = {
    for idx, runner in var.runners : idx => runner
  }

  name          = each.value.name
  description   = "Self-hosted GitHub Actions runner using AWS CodeBuild (${each.value.architecture}, ${each.value.size_label}, ${each.value.compute_type})"
  build_timeout = var.build_timeout
  service_role  = aws_iam_role.codebuild_service_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    # For FLEET: use ATTRIBUTE_BASED_COMPUTE with fleet block
    # For ON_DEMAND: use user-provided on_demand_compute_type (no fleet block)
    compute_type                = each.value.compute_type == "FLEET" ? "ATTRIBUTE_BASED_COMPUTE" : each.value.on_demand_compute_type
    image                       = each.value.image
    type                        = each.value.architecture == "arm64" ? "ARM_CONTAINER" : "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    # Privileged mode is required when running Docker-in-Docker inside a VPC
    privileged_mode = each.value.vpc_config != null ? true : false

    # Fleet block only for FLEET compute_type
    # ON_DEMAND uses ATTRIBUTE_BASED_COMPUTE without a fleet (on-demand execution)
    dynamic "fleet" {
      for_each = each.value.compute_type == "FLEET" ? [1] : []
      content {
        fleet_arn = aws_codebuild_fleet.github_runner[each.key].arn
      }
    }
  }

  source {
    type     = "GITHUB"
    location = var.github_repository_url != "" ? var.github_repository_url : "https://github.com/${var.github_username}/codebuild-runners-test"

    git_clone_depth = 1
    git_submodules_config {
      fetch_submodules = false
    }

    # Use CodeConnections if provided
    dynamic "auth" {
      for_each = var.codeconnections_connection_arn != "" ? [1] : []
      content {
        type     = "CODECONNECTIONS"
        resource = var.codeconnections_connection_arn
      }
    }
  }

  # VPC configuration at project level for on-demand projects only
  # For fleet projects (ATTRIBUTE_BASED_COMPUTE), VPC must be configured at the fleet level
  # VPC is not supported at project level when using ATTRIBUTE_BASED_COMPUTE (reserved capacity)
  dynamic "vpc_config" {
    for_each = each.value.compute_type == "ON_DEMAND" && each.value.vpc_config != null ? [1] : []
    content {
      vpc_id             = each.value.vpc_config.vpc_id
      subnets            = each.value.vpc_config.subnet_ids
      security_group_ids = [aws_security_group.codebuild[each.key].id]
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${each.value.name}"
      stream_name = "build-log"
    }
  }
}

# Webhooks for CodeBuild Runner projects
# Required, see: https://registry.terraform.io/providers/hashicorp/aws/6.9.0/docs/resources/codebuild_project#runner-project

# These webhooks listen for WORKFLOW_JOB_QUEUED events from GitHub Actions
resource "aws_codebuild_webhook" "github_runner" {
  for_each = {
    for idx, runner in var.runners : idx => runner
  }

  project_name = aws_codebuild_project.github_runner[each.key].name
  build_type   = "BUILD"

  filter_group {
    filter {
      type    = "EVENT"
      pattern = "WORKFLOW_JOB_QUEUED"
    }
  }
}
