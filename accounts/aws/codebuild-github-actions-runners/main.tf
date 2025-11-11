module "codebuild-github-actions-runners" {
  source = "../../../modules/codebuild-github-actions-runners"

  github_config                  = var.github_config
  build_timeout                  = var.build_timeout
  codeconnections_connection_arn = var.codeconnections_connection_arn
  runners                        = var.runners
  enable_s3_logging              = var.enable_s3_logging
  s3_logging_bucket_name         = var.s3_logging_bucket_name
}
