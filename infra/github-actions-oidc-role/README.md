# GitHub Actions OIDC Role

AWS IAM role for GitHub Actions using OIDC, restricted to your GitHub account repos.

## IAM Role Permissions

**Full admin access** to:
- **Amazon ECR**: Repository/image management
- **Amazon ECS**: Cluster/service/task management  
- **AWS Lambda**: Function/version/alias management

## Quick Start

1. Setup variables:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit with your github_username
   ```

2. Deploy:
   ```bash
   terraform init && terraform apply
   ```

3. Use in GitHub Actions:
   ```yaml
   - name: Configure AWS credentials
     uses: aws-actions/configure-aws-credentials@v4
     with:
       role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
       aws-region: eu-west-1
   ```

## Outputs

- `github_actions_role_arn`: Role ARN for secrets
- `github_oidc_provider_url`: OIDC provider URL
- `github_actions_setup_instructions`: Setup guide
