<!-- BEGIN_TF_DOCS -->
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


# Terraform Module Documentation

## Resources

| Name | Type |
|------|------|
| [aws_codebuild_fleet.github_runner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_fleet) | resource |
| [aws_codebuild_project.github_runner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project) | resource |
| [aws_codebuild_webhook.github_runner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_webhook) | resource |
| [aws_iam_policy.codebuild](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.codebuild_fleet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.codebuild_fleet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.codebuild_service_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.codebuild](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.codebuild_fleet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_s3_bucket.codebuild_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.codebuild_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_policy.codebuild_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.codebuild_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.codebuild_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_security_group.codebuild](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_iam_policy_document.codebuild](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.codebuild_service_role_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Default | Required |
|------|-------------|---------|:--------:|
| <a name="input_build_timeout"></a> [build\_timeout](#input\_build\_timeout) | Build timeout in minutes | `60` | no |
| <a name="input_codeconnections_connection_arn"></a> [codeconnections\_connection\_arn](#input\_codeconnections\_connection\_arn) | ARN of the AWS CodeConnections connection for GitHub. | n/a | yes |
| <a name="input_enable_s3_logging"></a> [enable\_s3\_logging](#input\_enable\_s3\_logging) | Enable S3 bucket logging for CodeBuild projects | `false` | no |
| <a name="input_github_config"></a> [github\_config](#input\_github\_config) | GitHub and webhook configuration. Controls both the CodeBuild source location and webhook scope. | n/a | yes |
| <a name="input_runners"></a> [runners](#input\_runners) | List of CodeBuild runners (mapping to CodeBuild build projects). Supports both Compute Fleets (with reserved capacity) and On-Demand projects. Defaults to one fleet runner: Linux x86\_64. | <pre>[<br/>  {<br/>    "architecture": "x86_64",<br/>    "compute_configuration": {<br/>      "disk_space": 64,<br/>      "memory": 4,<br/>      "vcpu_count": 2<br/>    },<br/>    "compute_type": "FLEET",<br/>    "image": "aws/codebuild/amazonlinux-x86_64-standard:5.0",<br/>    "minimum_capacity": 1,<br/>    "name": "github-runner-x86_64-small"<br/>  }<br/>]</pre> | no |
| <a name="input_s3_logging_bucket_name"></a> [s3\_logging\_bucket\_name](#input\_s3\_logging\_bucket\_name) | Name of the S3 logging bucket. Required when enable\_s3\_logging is true. | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_codebuild_project_arns"></a> [codebuild\_project\_arns](#output\_codebuild\_project\_arns) | Map of CodeBuild project ARNs keyed by runner index |
| <a name="output_codebuild_project_names"></a> [codebuild\_project\_names](#output\_codebuild\_project\_names) | Map of CodeBuild project names keyed by runner index |
| <a name="output_fleet_arns"></a> [fleet\_arns](#output\_fleet\_arns) | Map of fleet ARNs keyed by runner index and architecture (only for FLEET compute\_type) |
| <a name="output_fleet_ids"></a> [fleet\_ids](#output\_fleet\_ids) | Map of fleet IDs keyed by runner index and architecture (only for FLEET compute\_type) |
| <a name="output_fleet_names"></a> [fleet\_names](#output\_fleet\_names) | Map of fleet names keyed by runner index and architecture (only for FLEET compute\_type) |
| <a name="output_runner_names"></a> [runner\_names](#output\_runner\_names) | Map of runner names to CodeBuild project names |
| <a name="output_s3_logging_bucket"></a> [s3\_logging\_bucket](#output\_s3\_logging\_bucket) | S3 bucket name for CodeBuild logs (only available when enable\_s3\_logging is true) |
| <a name="output_workflow_runner_labels"></a> [workflow\_runner\_labels](#output\_workflow\_runner\_labels) | Available runner labels for use in GitHub Actions workflows |
<!-- END_TF_DOCS -->