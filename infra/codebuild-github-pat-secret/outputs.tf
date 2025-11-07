output "secret_arn" {
  description = "ARN of the Secrets Manager secret for GitHub PAT"
  value       = aws_secretsmanager_secret.github_pat.arn
}

output "secret_name" {
  description = "Name of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.github_pat.name
}

output "setup_instructions" {
  description = "Instructions for populating the secret"
  value       = <<-EOF
IMPORTANT: You must manually populate the secret after creation!

1. Go to AWS Secrets Manager console
2. Find the secret: ${aws_secretsmanager_secret.github_pat.name}
3. Click "Retrieve secret value" and then "Edit"
4. Update the secret value with your actual GitHub Personal Access Token
5. The secret MUST be in JSON format:
   {
     "ServerType": "GITHUB",
     "AuthType": "PERSONAL_ACCESS_TOKEN",
     "Token": "your-actual-token-here"
   }

For instructions on creating a GitHub PAT, see:
https://docs.aws.amazon.com/codebuild/latest/userguide/access-tokens-github.html

Secret ARN: ${aws_secretsmanager_secret.github_pat.arn}
EOF
}

