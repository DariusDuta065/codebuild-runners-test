# IAM Assume Role Policy for CodeBuild Service Role
data "aws_iam_policy_document" "codebuild_service_role_assume" {
  statement {
    sid    = "AllowCodeBuildServiceToAssumeRole"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# IAM Role for CodeBuild
resource "aws_iam_role" "codebuild_service_role" {
  name = "codebuild-github-actions-runners-service-role"

  assume_role_policy = data.aws_iam_policy_document.codebuild_service_role_assume.json
}

# IAM Policy Document for CodeBuild
# https://docs.aws.amazon.com/codebuild/latest/userguide/setting-up-service-role.html
data "aws_iam_policy_document" "codebuild" {
  # EC2 VPC and network interface permissions
  statement {
    sid    = "AllowEc2VpcAndNetworkInterfaceOperations"
    effect = "Allow"
    actions = [
      "ec2:DescribeVpcs",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeDhcpOptions",
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeNetworkInterfaces"
    ]
    resources = ["*"]
  }

  # EC2 network interface permission creation
  statement {
    sid    = "AllowEc2NetworkInterfacePermissionCreation"
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterfacePermission"
    ]
    resources = ["arn:aws:ec2:${data.aws_region.current.name}:*:network-interface/*"]
    condition {
      test     = "StringLike"
      variable = "ec2:Subnet"
      values   = ["arn:aws:ec2:${data.aws_region.current.name}:*:subnet/*"]
    }
    condition {
      test     = "StringLike"
      variable = "ec2:AuthorizedService"
      values   = ["codebuild.amazonaws.com"]
    }
  }

  # CloudWatch Logs permissions
  dynamic "statement" {
    for_each = length(var.runners) > 0 ? [1] : []
    content {
      sid    = "AllowCloudWatchLogsOperations"
      effect = "Allow"
      actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:GetLogEvents"
      ]
      resources = concat(
        [for idx, runner in var.runners : "arn:aws:logs:${data.aws_region.current.name}:*:log-group:/aws/codebuild/${runner.name}*"],
        [for idx, runner in var.runners : "arn:aws:logs:${data.aws_region.current.name}:*:log-group:/aws/codebuild/${runner.name}*:*"]
      )
    }
  }

  # CodeConnections permissions
  # When using CodeConnections, permissions must be scoped to the specific connection ARN
  # This is required for CodeBuild to automatically create webhooks via the GitHub App
  # Reference: https://docs.aws.amazon.com/codebuild/latest/userguide/multiple-access-tokens.html
  dynamic "statement" {
    for_each = var.codeconnections_connection_arn != "" ? [1] : []
    content {
      sid    = "AllowCodeConnectionsOperations"
      effect = "Allow"
      actions = [
        "codeconnections:GetConnectionToken",
        "codeconnections:GetConnection",
        "codeconnections:UseConnection",
        "codeconnections:ListConnections",
      ]
      resources = [var.codeconnections_connection_arn]
    }
  }

  # CodeBuild webhook permissions
  # CodeBuild needs these permissions to automatically create webhooks when using CodeConnections
  dynamic "statement" {
    for_each = length(var.runners) > 0 ? [1] : []
    content {
      sid    = "AllowCodeBuildWebhookManagement"
      effect = "Allow"
      actions = [
        "codebuild:CreateWebhook",
        "codebuild:UpdateWebhook",
        "codebuild:DeleteWebhook",
        "codebuild:ListWebhooks",
      ]
      # Allow webhook management for all CodeBuild projects in the region
      # CodeBuild service needs this to create webhooks for projects it manages
      resources = ["arn:aws:codebuild:${data.aws_region.current.name}:*:project/*"]
    }
  }
}

# IAM Policy for CodeBuild
resource "aws_iam_policy" "codebuild" {
  name        = "codebuild-github-actions-runners-service-role-policy"
  description = "Policy for CodeBuild GitHub Actions runner service role"

  policy = data.aws_iam_policy_document.codebuild.json
}

resource "aws_iam_role_policy_attachment" "codebuild" {
  role       = aws_iam_role.codebuild_service_role.name
  policy_arn = aws_iam_policy.codebuild.arn
}

# IAM Role for CodeBuild Fleet
resource "aws_iam_role" "codebuild_fleet" {
  count = length([for runner in var.runners : runner if runner.compute_type == "FLEET"]) > 0 ? 1 : 0
  name  = "codebuild-github-actions-runners-fleet-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "codebuild.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# IAM Policy for CodeBuild Fleet
# See: https://docs.aws.amazon.com/codebuild/latest/userguide/auth-and-access-control-iam-identity-based-access-control.html
# Heading: #customer-managed-policies-example-permission-policy-fleet-service-role
# Paragraph: Allow a user to add a permission policy for a fleet service role
resource "aws_iam_policy" "codebuild_fleet" {
  count       = length([for runner in var.runners : runner if runner.compute_type == "FLEET"]) > 0 ? 1 : 0
  name        = "codebuild-github-actions-runners-fleet-role-policy"
  description = "Policy for CodeBuild fleet service role"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEc2FleetInstanceManagement"
        Effect = "Allow"
        Action = [
          "ec2:CreateTags", "ec2:DescribeInstances", "ec2:DescribeInstanceStatus",
          "ec2:DescribeInstanceAttribute", "ec2:DescribeImages", "ec2:DescribeSnapshots",
          "ec2:DescribeSubnets", "ec2:DescribeVpcs", "ec2:DescribeSecurityGroups",
          "ec2:DescribeNetworkInterfaces", "ec2:DescribeAvailabilityZones",
          "ec2:DescribeDhcpOptions", "ec2:RunInstances", "ec2:TerminateInstances",
          "ec2:StartInstances", "ec2:StopInstances", "ec2:ModifyInstanceAttribute",
          "ec2:CreateNetworkInterface", "ec2:DeleteNetworkInterface",
          "ec2:AttachNetworkInterface", "ec2:DetachNetworkInterface",
          "ec2:CreateNetworkInterfacePermission", "ec2:DescribeNetworkInterfaceAttribute",
          "ec2:ModifyNetworkInterfaceAttribute"
        ]
        Resource = "*"
      },
      {
        Sid      = "AllowCloudWatchLogsForFleet"
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_fleet" {
  count      = length([for runner in var.runners : runner if runner.compute_type == "FLEET"]) > 0 ? 1 : 0
  role       = aws_iam_role.codebuild_fleet[0].name
  policy_arn = aws_iam_policy.codebuild_fleet[0].arn
}
