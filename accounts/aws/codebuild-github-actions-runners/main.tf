module "codebuild-github-actions-runners" {
  source = "../../../infra/codebuild-github-actions-runners"

  github_username                = var.github_username
  github_repository_url          = var.github_repository_url
  aws_region                     = var.aws_region
  build_timeout                  = var.build_timeout
  codeconnections_connection_arn = var.codeconnections_connection_arn
  runners                        = var.runners
}
