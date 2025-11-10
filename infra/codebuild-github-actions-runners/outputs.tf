output "codebuild_project_names" {
  description = "Map of CodeBuild project names keyed by runner index"
  value = {
    for idx, runner in var.runners : idx => aws_codebuild_project.github_runner[idx].name
  }
}

output "codebuild_project_arns" {
  description = "Map of CodeBuild project ARNs keyed by runner index"
  value = {
    for idx, runner in var.runners : idx => aws_codebuild_project.github_runner[idx].arn
  }
}

output "codebuild_project_names_by_arch_size" {
  description = "Map of CodeBuild project names keyed by architecture and size label"
  value = {
    for idx, runner in var.runners : "${runner.architecture}-${runner.size_label}" => aws_codebuild_project.github_runner[idx].name
  }
}

output "fleet_arns" {
  description = "Map of fleet ARNs keyed by runner index and architecture (only for FLEET compute_type)"
  value = {
    for idx, runner in var.runners : "${idx}-${runner.architecture}" => aws_codebuild_fleet.github_runner[idx].arn
    if runner.compute_type == "FLEET"
  }
}

output "fleet_ids" {
  description = "Map of fleet IDs keyed by runner index and architecture (only for FLEET compute_type)"
  value = {
    for idx, runner in var.runners : "${idx}-${runner.architecture}" => aws_codebuild_fleet.github_runner[idx].id
    if runner.compute_type == "FLEET"
  }
}

output "fleet_names" {
  description = "Map of fleet names keyed by runner index and architecture (only for FLEET compute_type)"
  value = {
    for idx, runner in var.runners : "${idx}-${runner.architecture}" => aws_codebuild_fleet.github_runner[idx].name
    if runner.compute_type == "FLEET"
  }
}

output "workflow_runner_labels" {
  description = "Available runner labels for use in GitHub Actions workflows"
  value       = [for idx, runner in var.runners : "codebuild-${aws_codebuild_project.github_runner[idx].name}-$${{ github.run_id }}-$${{ github.run_attempt }}"]
}

