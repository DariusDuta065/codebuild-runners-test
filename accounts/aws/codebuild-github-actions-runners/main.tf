module "codebuild-github-actions-runners" {
  source = "../../../infra/codebuild-github-actions-runners"

  codebuild_location             = var.codebuild_location
  build_timeout                  = var.build_timeout
  codeconnections_connection_arn = var.codeconnections_connection_arn
  runners                        = var.runners
}
