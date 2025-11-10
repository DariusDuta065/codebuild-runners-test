# CodeBuild Fleet
# Only created for FLEET compute_type (ON_DEMAND does not use fleets)
resource "aws_codebuild_fleet" "github_runner" {
  for_each = {
    for idx, runner in var.runners : idx => runner
    if runner.compute_type == "FLEET"
  }

  name               = each.value.name
  compute_type       = "ATTRIBUTE_BASED_COMPUTE"
  environment_type   = each.value.architecture == "arm64" ? "ARM_CONTAINER" : "LINUX_CONTAINER"
  base_capacity      = each.value.minimum_capacity
  fleet_service_role = aws_iam_role.codebuild_fleet[0].arn
  overflow_behavior  = "ON_DEMAND"

  compute_configuration {
    vcpu         = each.value.compute_configuration.vcpu_count
    memory       = each.value.compute_configuration.memory
    disk         = each.value.compute_configuration.disk_space
    machine_type = "GENERAL"
  }

  dynamic "vpc_config" {
    for_each = each.value.vpc_config != null ? [1] : []
    content {
      vpc_id             = each.value.vpc_config.vpc_id
      subnets            = each.value.vpc_config.subnet_ids
      security_group_ids = [aws_security_group.codebuild[each.key].id]
    }
  }
}
