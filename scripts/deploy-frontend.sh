#!/bin/bash

set -euo pipefail

REPOSITORY_URL="https://github.com/eli0504167101/Terraform-01.git"
PROJECT_DIRECTORY="/home/ec2-user/Terraform-01"
IMAGE_NAME="terraform-frontend:1.0"
CONTAINER_NAME="frontend"

if ! command -v git >/dev/null 2>&1; then
  sudo dnf install -y git
fi

if [ -d "${PROJECT_DIRECTORY}/.git" ]; then
  git -C "${PROJECT_DIRECTORY}" pull --ff-only
else
  git clone "${REPOSITORY_URL}" "${PROJECT_DIRECTORY}"
fi

docker build \
  -t "${IMAGE_NAME}" \
  "${PROJECT_DIRECTORY}/frontend"

docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true

docker run \
  -d \
  --name "${CONTAINER_NAME}" \
  --restart unless-stopped \
  -p 80:80 \
  "${IMAGE_NAME}"

docker ps --filter "name=${CONTAINER_NAME}"