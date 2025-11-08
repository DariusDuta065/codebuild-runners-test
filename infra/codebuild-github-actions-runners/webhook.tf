# CodeBuild Webhook for GitHub Actions
# Note: Webhook requires GitHub PAT to be configured in the source auth first
resource "aws_codebuild_webhook" "github" {
  project_name = aws_codebuild_project.github_runner.name
  build_type   = "BUILD"

  filter_group {
    filter {
      type    = "EVENT"
      pattern = "WORKFLOW_JOB_QUEUED"
    }
  }
}

