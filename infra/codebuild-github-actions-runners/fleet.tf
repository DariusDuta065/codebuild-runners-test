resource "aws_security_group" "fleet" {
  for_each = {
    for idx, fleet in var.compute_fleets : idx => fleet
    if fleet.vpc_config != null
  }

  name        = "${each.value.name}-sg"
  description = "Security group for CodeBuild fleet ${each.value.name}"
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
    Name         = "${each.value.name}-sg"
    Architecture = each.value.architecture
    Size         = each.value.size_label
  }
}

# CodeBuild Fleet
resource "aws_codebuild_fleet" "github_runner" {
  for_each = {
    for idx, fleet in var.compute_fleets : idx => fleet
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
      security_group_ids = [aws_security_group.fleet[each.key].id]
    }
  }
}
