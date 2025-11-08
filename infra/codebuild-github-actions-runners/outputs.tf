output "codebuild_project_names" {
  description = "Map of CodeBuild project names keyed by fleet index"
  value = {
    for idx, fleet in var.compute_fleets : idx => aws_codebuild_project.github_runner[idx].name
  }
}

output "codebuild_project_arns" {
  description = "Map of CodeBuild project ARNs keyed by fleet index"
  value = {
    for idx, fleet in var.compute_fleets : idx => aws_codebuild_project.github_runner[idx].arn
  }
}

output "codebuild_project_names_by_arch_size" {
  description = "Map of CodeBuild project names keyed by architecture and size label"
  value = {
    for idx, fleet in var.compute_fleets : "${fleet.architecture}-${fleet.size_label}" => aws_codebuild_project.github_runner[idx].name
  }
}

output "github_pat_secret_arn" {
  description = "ARN of the Secrets Manager secret for GitHub PAT (passed as input variable)"
  value       = var.github_pat_secret_arn
}

output "fleet_arns" {
  description = "Map of fleet ARNs keyed by fleet index and architecture"
  value = {
    for idx, fleet in var.compute_fleets : "${idx}-${fleet.architecture}" => aws_codebuild_fleet.github_runner[idx].arn
  }
}

output "fleet_ids" {
  description = "Map of fleet IDs keyed by fleet index and architecture"
  value = {
    for idx, fleet in var.compute_fleets : "${idx}-${fleet.architecture}" => aws_codebuild_fleet.github_runner[idx].id
  }
}

output "fleet_names" {
  description = "Map of fleet names keyed by fleet index and architecture"
  value = {
    for idx, fleet in var.compute_fleets : "${idx}-${fleet.architecture}" => aws_codebuild_fleet.github_runner[idx].name
  }
}

output "workflow_runner_labels" {
  description = "Available runner labels for use in GitHub Actions workflows"
  value       = [for idx, fleet in var.compute_fleets : "codebuild-${aws_codebuild_project.github_runner[idx].name}-$${{ github.run_id }}-$${{ github.run_attempt }}"]
}

