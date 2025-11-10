# CodeBuild GitHub Actions Runners

Terraform module for setting up self-hosted GitHub Actions runners using AWS CodeBuild. Supports both Compute Fleets (with reserved capacity) and On-Demand projects.

## Overview

This module creates CodeBuild projects for running GitHub Actions workflows. Each runner configuration creates:
- A CodeBuild project (either associated with a compute fleet or configured for on-demand execution)
- IAM roles and policies
- Optional VPC configuration

## Features

### Compute Types

- **FLEET**: Uses CodeBuild compute fleets with reserved capacity. Requires `minimum_capacity` to be set. Overflow builds automatically run on-demand.
- **ON_DEMAND**: Uses on-demand CodeBuild compute without reserved capacity. No `minimum_capacity` required.

### VPC Configuration (optional)

- Configure runners to run inside your VPC
- Security groups automatically created with required egress rules
- Fleet runners: VPC configured at fleet level
- On-demand runners: VPC configured at project level

### Connection to GitHub via GitHub App and CodeConnections

- Secure authentication using AWS CodeConnections with GitHub App
- No Personal Access Tokens required
- Automatic webhook management

### Webhooks

- Automatically created for each runner project
- Listens for `WORKFLOW_JOB_QUEUED` events from GitHub Actions


## Quick Start

1. **Set up GitHub App connection via AWS Console:**
   - Navigate to the [AWS CodeBuild Console](https://console.aws.amazon.com/codebuild/home)
   - In the navigation pane, choose **Settings**, then select **Connections**
   - Click **Create connection**
   - For **Provider type**, choose **GitHub**
   - Click **Install a new app** (this redirects to GitHub to install the **AWS Connector for GitHub**)
   - On GitHub, select the account/organization where you want to install the app
   - Review permissions and repository access, then click **Install**
   - Return to the AWS CodeBuild console and select the newly installed app from the dropdown
   - Click **Connect** to finalize the connection
   - Copy the connection ARN (you'll need it for the `codeconnections_connection_arn` variable)
   
   For detailed instructions, see the [AWS documentation on GitHub App connections](https://docs.aws.amazon.com/codebuild/latest/userguide/connections-github-app.html).

2. Configure variables:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit with your values, including the codeconnections_connection_arn from step 1
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
- `codebuild_project_names`: Map of project names keyed by runner index
- `codebuild_project_arns`: Map of project ARNs keyed by runner index
- `codebuild_project_names_by_arch_size`: Map of project names keyed by architecture and size label
- `fleet_arns`: Map of fleet ARNs keyed by runner index and architecture (only for FLEET compute_type)
- `fleet_ids`: Map of fleet IDs keyed by runner index and architecture (only for FLEET compute_type)
- `fleet_names`: Map of fleet names keyed by runner index and architecture (only for FLEET compute_type)
