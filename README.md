# codebuild-runners-test

Testing self-hosted GitHub Actions runners using AWS CodeBuild.

## Infrastructure Overview

- `infra/account-baseline-setup`: Account-specific baseline infrastructure for a low-usage AWS account, including EC2 NAT instance configuration.
  - `ec2-nat-instance`: Configures an EC2 instance to act as a NAT gateway using FCK-NAT, providing a cost-effective alternative to managed NAT gateways (approximately 90% cost reduction).
  - `ec2-private-subnet-nat-instance-test`: Launches a test EC2 instance in a private subnet for validating NAT functionality via SSM Session Manager.
  - `github-actions-oidc-role`: Configures IAM OIDC provider and role for GitHub Actions to authenticate with AWS without long-lived credentials.
  - `private-ecr-repo-example`: Example ECR repository for testing container image push and pull operations from private subnets.
  - `private-subnets-nat-gateway`: Creates private subnets for the default VPC, which does not include private subnets by default.
- `infra/codebuild-github-actions-runners`: Configures self-hosted GitHub Actions runners using AWS CodeBuild, including compute fleets, webhooks, and VPC integration.
- `infra/github-pat-secret`: Creates an AWS Secrets Manager secret containing a GitHub Personal Access Token formatted in the JSON structure required by CodeBuild.

## Discoveries

- One CodeBuild project maps directly to one webhook. Multiple webhooks are required for multiple projects to avoid developers specifying fleet labels in `runs-on`. GitHub limits webhooks to 20 per event type for both repositories and organizations (250 for GitHub Enterprise Server).
- CodeBuild reserved capacity is used as part of our DR strategy to improve the resilience of the CI/CD platform by always having at least N runners available of each type, ensuring we never have to compete with other AWS customers for capacity. Reserved capacity for a 2 vCPU, 4GB RAM instance costs approximately $36-72 per month per instance (pricing varies by region and may change).
- VPC integration should be avoided unless necessary. The goal is to have managed GitHub runners that don't require maintenance and reduce support tickets. The CI/CD system should remain stateless to ensure consistent behavior across different runners—running the same job on two different runners should behave exactly the same. Integrating runners with different VPCs risks losing statelessness as teams may request VPC-specific connections.
  - Enabling VPC integration gives access to VPC endpoints, which are a cost-saving feature rather than a performance feature. As current costs are $0, we should wait and observe when it's worth adding VPC endpoints for services like ECR, S3, and others, balancing the costs with all other factors and risks involved.
- CodeBuild has a [Docker Server capability](https://aws.amazon.com/blogs/aws/accelerate-ci-cd-pipelines-with-the-new-aws-codebuild-docker-server-capability/) feature, which is a dedicated persistent Docker server that can accelerate Docker image builds by centralizing image building to a remote host with persistent caching. However, as noted at the end of the blog post, ARM builds are not supported. Since we are heavily pushing for ARM as it's cheaper and faster, we cannot use this feature for this reason, so it's not going to be taken into consideration.
- When using CodeBuild compute fleets, VPC configuration is done within the fleet definition, not at the CodeBuild project level.
