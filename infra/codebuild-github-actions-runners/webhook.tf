# CodeBuild Webhooks for GitHub Actions - one per project/fleet
# Note: Webhook requires GitHub PAT to be configured in the source auth first
resource "aws_codebuild_webhook" "github" {
  for_each = {
    for idx, fleet in var.compute_fleets : idx => fleet
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
