# CodeBuild Projects - one per fleet
resource "aws_codebuild_project" "github_runner" {
  for_each = {
    for idx, fleet in var.compute_fleets : idx => fleet
  }

  name          = each.value.name
  description   = "Self-hosted GitHub Actions runner using AWS CodeBuild (${each.value.architecture}, ${each.value.size_label})"
  build_timeout = var.build_timeout
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "ATTRIBUTE_BASED_COMPUTE"
    image                       = each.value.image
    type                        = each.value.architecture == "arm64" ? "ARM_CONTAINER" : "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    # Privileged mode is required when running Docker-in-Docker inside a VPC
    # VPC is configured at the fleet level, so check if fleet has VPC config
    privileged_mode = each.value.vpc_config != null ? true : false

    fleet {
      fleet_arn = aws_codebuild_fleet.github_runner[each.key].arn
    }

    environment_variable {
      name  = "GITHUB_PAT_SECRET_ARN"
      value = var.github_pat_secret_arn
    }
  }

  source {
    type     = "GITHUB"
    location = var.github_repository_url != "" ? var.github_repository_url : "https://github.com/${var.github_username}/codebuild-runners-test"

    git_clone_depth = 1
    git_submodules_config {
      fetch_submodules = false
    }

    # Note: Auth will be configured after GitHub PAT secret is updated with actual token
    auth {
      type     = "SECRETS_MANAGER"
      resource = var.github_pat_secret_arn
    }
  }

  # Note: VPC configuration is handled at the fleet level when using ATTRIBUTE_BASED_COMPUTE
  # Do not specify vpc_config at the project level when using fleets

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${each.value.name}"
      stream_name = "build-log"
    }
  }
}
