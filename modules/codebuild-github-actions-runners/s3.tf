# S3 bucket for CodeBuild logs - created conditionally based on enable_s3_logging

# S3 Bucket for CodeBuild Logs
resource "aws_s3_bucket" "codebuild_logs" {
  count  = var.enable_s3_logging ? 1 : 0
  bucket = var.s3_logging_bucket_name
}

# Block all public access to S3 bucket
resource "aws_s3_bucket_public_access_block" "codebuild_logs" {
  count  = var.enable_s3_logging ? 1 : 0
  bucket = aws_s3_bucket.codebuild_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable server-side encryption (AWS S3 managed encryption)
resource "aws_s3_bucket_server_side_encryption_configuration" "codebuild_logs" {
  count  = var.enable_s3_logging ? 1 : 0
  bucket = aws_s3_bucket.codebuild_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

# Enforce HTTPS-only access via bucket policy
resource "aws_s3_bucket_policy" "codebuild_logs" {
  count  = var.enable_s3_logging ? 1 : 0
  bucket = aws_s3_bucket.codebuild_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.codebuild_logs[0].arn,
          "${aws_s3_bucket.codebuild_logs[0].arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# Lifecycle policy: Delete objects older than 365 days
resource "aws_s3_bucket_lifecycle_configuration" "codebuild_logs" {
  count  = var.enable_s3_logging ? 1 : 0
  bucket = aws_s3_bucket.codebuild_logs[0].id

  rule {
    id     = "delete-old-logs"
    status = "Enabled"

    filter {
      prefix = "codebuild-logs/"
    }

    expiration {
      days = 365
    }
  }
}

