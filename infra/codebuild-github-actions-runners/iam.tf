# IAM Role for CodeBuild
resource "aws_iam_role" "codebuild" {
  name = "${var.project_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# IAM Policy for CodeBuild
resource "aws_iam_policy" "codebuild" {
  name        = "${var.project_name}-policy"
  description = "Policy for CodeBuild GitHub Actions runner"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = var.github_pat_secret_arn
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeDhcpOptions",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeNetworkInterfaces"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterfacePermission"
        ]
        Resource = "arn:aws:ec2:${var.aws_region}:*:network-interface/*"
        Condition = {
          StringLike = {
            "ec2:Subnet" = [
              "arn:aws:ec2:${var.aws_region}:*:subnet/*"
            ]
            "ec2:AuthorizedService" = "codebuild.amazonaws.com"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents"
        ]
        Resource = [
          "arn:aws:logs:${var.aws_region}:*:log-group:/aws/codebuild/${var.project_name}*",
          "arn:aws:logs:${var.aws_region}:*:log-group:/aws/codebuild/${var.project_name}*:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild" {
  role       = aws_iam_role.codebuild.name
  policy_arn = aws_iam_policy.codebuild.arn
}

# IAM Role for CodeBuild Fleet
resource "aws_iam_role" "codebuild_fleet" {
  count = length(var.compute_fleets) > 0 ? 1 : 0
  name  = "${var.project_name}-fleet-role"

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
resource "aws_iam_policy" "codebuild_fleet" {
  count       = length(var.compute_fleets) > 0 ? 1 : 0
  name        = "${var.project_name}-fleet-policy"
  description = "Policy for CodeBuild fleet service role"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
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
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:${var.aws_region}:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_fleet" {
  count      = length(var.compute_fleets) > 0 ? 1 : 0
  role       = aws_iam_role.codebuild_fleet[0].name
  policy_arn = aws_iam_policy.codebuild_fleet[0].arn
}

