#!/bin/bash
set -e

ECR_REPO_URL=${1:-${ECR_REPO_URL:-590624982938.dkr.ecr.eu-west-1.amazonaws.com}}

if [ -z "$ECR_REPO_URL" ]; then
  echo "Usage: $0 <ecr-repo-url>"
  echo "   or: ECR_REPO_URL=<ecr-repo-url> $0"
  exit 1
fi

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

aws ecr get-login-password | docker login --username AWS --password-stdin $ECR_REPO_URL

echo "Building Docker image from Dockerfile..."
docker build -t ${ECR_REPO_URL}/200mb-image:latest -f ${SCRIPT_DIR}/Dockerfile ${SCRIPT_DIR}

echo "Pushing image to ECR..."
docker push ${ECR_REPO_URL}/200mb-image:latest

echo "Successfully pushed 200mb-image to ${ECR_REPO_URL}"

