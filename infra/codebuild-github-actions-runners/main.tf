# CodeBuild Project
resource "aws_codebuild_project" "github_runner" {
  name          = var.project_name
  description   = "Self-hosted GitHub Actions runner using AWS CodeBuild"
  build_timeout = var.build_timeout
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    # Privileged mode is required when running Docker-in-Docker inside a VPC
    privileged_mode = var.vpc_id != "" ? true : false

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

  dynamic "vpc_config" {
    for_each = var.vpc_id != "" ? [1] : []
    content {
      vpc_id             = data.aws_vpc.main[0].id
      subnets            = local.codebuild_subnet_ids
      security_group_ids = [aws_security_group.codebuild[0].id]
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${var.project_name}"
      stream_name = "build-log"
    }
  }
}
