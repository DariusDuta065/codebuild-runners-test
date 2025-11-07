output "codebuild_project_name" {
  description = "Name of the CodeBuild project"
  value       = aws_codebuild_project.github_runner.name
}

output "codebuild_project_arn" {
  description = "ARN of the CodeBuild project"
  value       = aws_codebuild_project.github_runner.arn
}

output "github_pat_secret_arn" {
  description = "ARN of the Secrets Manager secret for GitHub PAT (passed as input variable)"
  value       = var.github_pat_secret_arn
}

output "security_group_id" {
  description = "Security group ID for CodeBuild (empty if VPC is disabled)"
  value       = var.vpc_id != "" ? aws_security_group.codebuild[0].id : null
}

output "setup_instructions" {
  description = "Instructions for using the runner"
  value       = <<-EOF
1. Ensure the GitHub PAT secret is created and populated:
   - The secret ARN is: ${var.github_pat_secret_arn}
   - Make sure the secret is populated with your actual GitHub Personal Access Token
   - The secret must be in JSON format:
     {
       "ServerType": "GITHUB",
       "AuthType": "PERSONAL_ACCESS_TOKEN",
       "Token": "your-actual-token-here"
     }
   - For instructions on creating a GitHub PAT, see: https://docs.aws.amazon.com/codebuild/latest/userguide/access-tokens-github.html

2. Use the runner in your GitHub Actions workflow:
   Add the following to your workflow YAML:
   
   jobs:
     build:
       runs-on: codebuild-${aws_codebuild_project.github_runner.name}-$${{ github.run_id }}-$${{ github.run_attempt }}
       steps:
         - name: Checkout code
           uses: actions/checkout@v3
         # Add your steps here

3. CodeBuild Project Name: ${aws_codebuild_project.github_runner.name}
4. CodeBuild Project ARN: ${aws_codebuild_project.github_runner.arn}
5. Security Group ID: ${var.vpc_id != "" ? aws_security_group.codebuild[0].id : "N/A (VPC disabled)"}
EOF
}

