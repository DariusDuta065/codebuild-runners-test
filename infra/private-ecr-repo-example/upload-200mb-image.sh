#!/bin/bash
set -e

ECR_REPO_URL=${1:-${ECR_REPO_URL:-590624982938.dkr.ecr.eu-west-1.amazonaws.com}}

aws ecr get-login-password | docker login --username AWS --password-stdin $ECR_REPO_URL

if [ -z "$ECR_REPO_URL" ]; then
  echo "Usage: $0 <ecr-repo-url>"
  echo "   or: ECR_REPO_URL=<ecr-repo-url> $0"
  exit 1
fi

docker pull public.ecr.aws/nginx/nginx:latest
docker tag public.ecr.aws/nginx/nginx:latest ${ECR_REPO_URL}/200mb-image:latest
docker push ${ECR_REPO_URL}/200mb-image:latest

echo "Successfully pushed 200mb-image to ${ECR_REPO_URL}"

