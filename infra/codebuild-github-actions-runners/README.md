# CodeBuild GitHub Actions Runners

Terraform module for setting up self-hosted GitHub Actions runners using AWS CodeBuild compute fleets.

## Overview

This module creates CodeBuild projects and compute fleets for running GitHub Actions workflows. Each fleet configuration creates:
- A CodeBuild project associated with a compute fleet
- A webhook for automatic workflow triggering
- IAM roles and policies
- Optional VPC configuration

## Quick Start

1. Create GitHub PAT secret (required):
   - Use the `codebuild-github-pat-secret` module to create the secret
   - The secret must contain your GitHub Personal Access Token in JSON format:
     ```json
     {
       "ServerType": "GITHUB",
       "AuthType": "PERSONAL_ACCESS_TOKEN",
       "Token": "your-actual-token-here"
     }
     ```

2. Configure variables:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit with your values, including compute_fleets configuration
   ```

3. Deploy:
   ```bash
   terraform init && terraform apply
   ```

4. Use in GitHub Actions:
   ```yaml
   jobs:
     build:
       runs-on: codebuild-<PROJECT_NAME>-${{ github.run_id }}-${{ github.run_attempt }}
       steps:
         - name: Checkout code
           uses: actions/checkout@v5
   ```
   
   Available labels are shown in the `workflow_runner_labels` output.

## Outputs

- `workflow_runner_labels`: Array of runner labels for use in GitHub Actions workflows
- `codebuild_project_names`: Map of project names keyed by fleet index
- `codebuild_project_arns`: Map of project ARNs keyed by fleet index
- `fleet_names`: Map of fleet names keyed by fleet index and architecture
- `github_pat_secret_arn`: ARN of the Secrets Manager secret

