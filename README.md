# codebuild-runners-test

Testing self-hosted GitHub Actions runners using AWS CodeBuild.

## Known Problems

- CodeBuild on-demand can take up to 90 seconds to provision a new server.
  - The solution would be to cover as many jobs with reserved capacity as possible (20s to see progress on GitHub Actions Web UI)
- Out of ~100 Webhook calls (GitHub -> CodeBuild, in order to trigger a build), only 1 failed to deliver and had to be manually retried.
  - The solution would be to write a custom Lambda function to handle the webhook delivery and retry logic.
  - GitHub will **not** retry webhook delivery: [source](https://docs.github.com/en/webhooks/testing-and-troubleshooting-webhooks/redelivering-webhooks) 
    - The reason is that GitHub does not know if the webhook was handled and refused (e.g. we have 2 CodeBuild projects (X86 and ARM) with 2 Webhooks, only the ARM one should be called, but GitHub would call *all* webhooks and let them refuse the call (the X86 would say "Wrong project name" and return a non-200 status code)
- DR: The availability of this solution strictly depends on the combined availability of GitHub Webhooks and CodeBuild. Since the solution is fully-managed, we depend on these two services to be available. The Lambda function that retries webhook deliveries can help improve the availability by retrying the delivery with an exponential backoff.
  - However, if GitHub Webhooks are not available, then we're stuck waiting for GitHub to resume webhook deliveries.
  

## Infrastructure Overview

- `modules/account-baseline-setup`: Account-specific baseline infrastructure for a low-usage AWS account, including EC2 NAT instance configuration.
  - `ec2-nat-instance`: Configures an EC2 instance to act as a NAT gateway using FCK-NAT, providing a cost-effective alternative to managed NAT gateways (approximately 90% cost reduction).
  - `ec2-private-subnet-nat-instance-test`: Launches a test EC2 instance in a private subnet for validating NAT functionality via SSM Session Manager.
  - `github-actions-oidc-role`: Configures IAM OIDC provider and role for GitHub Actions to authenticate with AWS without long-lived credentials.
  - `private-ecr-repo-example`: Example ECR repository for testing container image push and pull operations from private subnets.
  - `private-subnets-nat-gateway`: Creates private subnets for the default VPC, which does not include private subnets by default.
- `modules/codebuild-github-actions-runners`: Configures self-hosted GitHub Actions runners using AWS CodeBuild, including compute fleets, webhooks, and VPC integration.

## Discoveries

- **One CodeBuild project maps directly to one webhook**. Multiple webhooks are required for multiple projects to avoid developers specifying fleet labels in `runs-on`. GitHub limits webhooks to 20 per event type for both repositories and organizations (250 for GitHub Enterprise Server).
  - GitHub sends the webhook payload to all webhooks for the event type (e.g. `workflow_job_queued`) for the repository or organization. This is fine, as CodeBuild Build Projects that do not match the `runs-on` label will return a 400 Bad Request status code, saying: (`{"message":"Project name in label gha-x86-small did not match actual project name"}`).
  - Only the matching CodeBuild Project will actually run the job.
- **CodeBuild reserved capacity** can be used as part of our DR strategy to improve the resilience of the CI/CD platform by always having at least N runners available of each type, ensuring we never have to compete with other AWS customers for capacity. Reserved capacity for a 2 vCPU, 4GB RAM instance costs approximately $36-72 per month per instance (pricing varies by region and may change).
- **Compute fleet overflow behavior** has been tested and works correctly. When demand exceeds reserved capacity, overflow jobs automatically run on-demand with CodeBuild.
  - Reserved capacity provisioning: Internal CodeBuild provisioning time is approximately 3 seconds, with total wait time from job start to execution typically 20-30 seconds.
  - On-demand provisioning: Requires an additional ~15 seconds for CodeBuild to provision a new server, resulting in total wait times of 30-45 seconds. Observed maximum queue time for on-demand builds is up to 90 seconds.
  - Reserved capacity significantly reduces queuing and provisioning time compared to on-demand, making it essential for consistent CI/CD performance.
- **VPC integration should be avoided unless necessary**. The goal is to have managed GitHub runners that don't require maintenance and reduce support tickets. The CI/CD system should remain stateless to ensure consistent behavior across different runners—running the same job on two different runners should behave exactly the same. Integrating runners with different VPCs risks losing statelessness as teams may request VPC-specific connections.
  - Enabling VPC integration gives access to VPC endpoints, which are a cost-saving feature rather than a performance feature. As current costs are $0, we should wait and observe when it's worth adding VPC endpoints for services like ECR, S3, and others, balancing the costs with all other factors and risks involved.
- CodeBuild has a [Docker Server capability](https://aws.amazon.com/blogs/aws/accelerate-ci-cd-pipelines-with-the-new-aws-codebuild-docker-server-capability/) feature, which is a dedicated persistent Docker server that can accelerate Docker image builds by centralizing image building to a remote host with persistent caching. However, as noted at the end of the blog post, ARM builds are not supported. 
  - Since we are heavily pushing for ARM as it's cheaper and faster, **we cannot use this feature** for this reason, so it's not going to be taken into consideration.
- When using CodeBuild compute fleets, VPC configuration is done within the fleet definition, not at the CodeBuild project level.
- When using AWS CodeConnections with CodeBuild, the **CodeBuild service role needs permissions to associate the connection with the build project**. 
  - The service role requires `codeconnections:UseConnection`, `codeconnections:ListConnections`, and `codeconnections:GetConnection` permissions. CodeBuild automatically associates the CodeConnections connection to the project when the service role has these permissions—no additional configuration is needed beyond specifying the connection ARN in the source auth block.

---

# GitHub Apps Limitations
If your company already has an AWS CodeBuild GitHub App integration set up—whether in the same or different AWS accounts or regions—it is possible to have multiple such integrations without them impacting or interfering with each other. GitHub Apps and CodeBuild connections are designed to allow independent, account- and region-scoped setups.

### Multiple GitHub App Installations

- GitHub Apps can be installed on multiple GitHub organizations, repositories, or personal accounts, and there is no technical restriction on the number of simultaneous installations. Each installation is independent and governed by its own permissions and repository access scopes.
- When you install the AWS CodeBuild App in a GitHub organization or repo, you can choose which repositories to grant it access to. These choices do not affect other installations or AWS accounts using their own CodeBuild connections, even if they're pointed at the same or different repositories.

### AWS Account and Region Segmentation

- Each AWS account can create its own CodeBuild GitHub App connection, even if the same company manages multiple AWS accounts for different environments (development, staging, production, etc.).
- CodeBuild connections are generally region-specific. Connections created in a specific AWS region can only be used in that region, meaning connections in account A in US East (N. Virginia) and account B in EU (Frankfurt) are entirely separate and will not conflict.
- If you need to share a connection across multiple AWS accounts, AWS supports connection sharing features, allowing controlled cross-account access without impacting other setups.

### Independence and No Mutual Impact

- Multiple CodeBuild App connections (whether across different AWS accounts or regions) operate independently without interfering with each other’s triggers, permissions, or build pipelines.
- Permissions, triggers, and repository access for each App installation are configured separately, ensuring that changing or deleting one does not affect the others.

### Summary Table

| Scenario                                | Multiple CodeBuild Apps | Impact/Interference        |
|------------------------------------------|:----------------------:|:--------------------------:|
| Multiple AWS accounts, same region       | Yes                    | No                         |
| Multiple AWS accounts, different regions | Yes                    | No                         |
| Multiple organizations on GitHub         | Yes                    | No                         |
