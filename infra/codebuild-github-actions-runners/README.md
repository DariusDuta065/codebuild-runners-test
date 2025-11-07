# CodeBuild GitHub Actions Runners

Terraform module for setting up self-hosted GitHub Actions runners using AWS CodeBuild.

## Overview

This module creates the necessary AWS resources to run GitHub Actions workflows on AWS CodeBuild infrastructure. It includes:

- AWS Secrets Manager secret for GitHub Personal Access Token (PAT)
- IAM role and policies for CodeBuild
- Security group for VPC access
- CodeBuild project configured for GitHub Actions runners
- Webhook configuration for automatic triggering

## Quick Start

1. Setup variables:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit with your github_username and other values
   ```

2. Deploy:
   ```bash
   terraform init && terraform apply
   ```

3. Update GitHub PAT:
   - Go to AWS Secrets Manager console
   - Find the secret created by this module
   - Update the secret value with your actual GitHub Personal Access Token
   - **Important**: The secret must be in JSON format:
     ```json
     {
       "ServerType": "GITHUB",
       "AuthType": "PERSONAL_ACCESS_TOKEN",
       "Token": "your-actual-token-here"
     }
     ```
   - For instructions on creating a GitHub PAT, see: [AWS Documentation - GitHub and GitHub Enterprise Server access token](https://docs.aws.amazon.com/codebuild/latest/userguide/access-tokens-github.html)

4. Use in GitHub Actions:
   ```yaml
   jobs:
     build:
       runs-on: codebuild-github-runner-${{ github.run_id }}-${{ github.run_attempt }}
       steps:
         - name: Checkout code
           uses: actions/checkout@v3
         # Add your steps here
   ```

## Outputs

- `codebuild_project_name`: Name of the CodeBuild project
- `codebuild_project_arn`: ARN of the CodeBuild project
- `github_pat_secret_arn`: ARN of the Secrets Manager secret
- `security_group_id`: Security group ID for CodeBuild
- `setup_instructions`: Detailed setup instructions

