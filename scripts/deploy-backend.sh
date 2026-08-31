#!/bin/bash

set -euo pipefail

REPOSITORY_URL="https://github.com/eli0504167101/Terraform-01.git"
PROJECT_DIRECTORY="/home/ec2-user/Terraform-01"
IMAGE_NAME="terraform-backend:1.0"
CONTAINER_NAME="backend"
ENVIRONMENT_FILE="/home/ec2-user/backend.env"

if ! command -v git >/dev/null 2>&1; then
  sudo dnf install -y git
fi

if [ -d "${PROJECT_DIRECTORY}/.git" ]; then
  git -C "${PROJECT_DIRECTORY}" pull --ff-only
else
  git clone "${REPOSITORY_URL}" "${PROJECT_DIRECTORY}"
fi

if [ ! -f "${ENVIRONMENT_FILE}" ]; then
  echo "Missing environment file: ${ENVIRONMENT_FILE}"
  exit 1
fi

docker build \
  -t "${IMAGE_NAME}" \
  "${PROJECT_DIRECTORY}/backend"

docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true

docker run \
  -d \
  --name "${CONTAINER_NAME}" \
  --restart unless-stopped \
  --env-file "${ENVIRONMENT_FILE}" \
  -p 5000:5000 \
  -v backend-data:/data \
  "${IMAGE_NAME}"
  

docker ps --filter "name=${CONTAINER_NAME}"
