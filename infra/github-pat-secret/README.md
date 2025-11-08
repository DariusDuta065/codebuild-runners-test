# CodeBuild GitHub PAT Secret

This module creates and manages the AWS Secrets Manager secret for the GitHub Personal Access Token used by CodeBuild GitHub Actions runners.

## Important: Secret Population

**You MUST manually populate the secret after creation!**

The secret is created with a placeholder value. After applying this Terraform configuration:

1. Go to AWS Secrets Manager console
2. Find the secret (named `{secret_name}-github-pat`)
3. Click "Retrieve secret value" and then "Edit"
4. Update the secret value with your actual GitHub Personal Access Token
5. The secret MUST be in JSON format:
   ```json
   {
     "ServerType": "GITHUB",
     "AuthType": "PERSONAL_ACCESS_TOKEN",
     "Token": "your-actual-token-here"
   }
   ```

For instructions on creating a GitHub PAT, see:
https://docs.aws.amazon.com/codebuild/latest/userguide/access-tokens-github.html

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and configure
2. Run `terraform init`
3. Run `terraform plan`
4. Run `terraform apply`
5. **Manually populate the secret** (see above)
6. Use the output `secret_arn` in your CodeBuild runner module

## Variables

- `aws_region` - AWS region where the secret will be created (default: "eu-west-1")
- `secret_name` - Base name for the secret (default: "github-runner")
- `tags` - Tags to apply to the secret

## Outputs

- `secret_arn` - ARN of the Secrets Manager secret (use this in the CodeBuild runner module)
- `secret_name` - Name of the Secrets Manager secret
- `setup_instructions` - Instructions for populating the secret

