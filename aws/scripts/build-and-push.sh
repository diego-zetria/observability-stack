#!/usr/bin/env bash
set -eu

AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID:-123456789012}
AWS_REGION=${AWS_REGION:-us-east-1}
REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
CONFIGS_DIR="$(cd "$(dirname "$0")/../configs" && pwd)"

echo "==> Logging into ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${REGISTRY}

# Create repos if they don't exist
for repo in obs-monitoring-loki obs-monitoring-tempo obs-monitoring-alloy obs-monitoring-grafana; do
  aws ecr describe-repositories --repository-names ${repo} --region ${AWS_REGION} 2>/dev/null || \
    aws ecr create-repository --repository-name ${repo} --region ${AWS_REGION} --image-scanning-configuration scanOnPush=true
done

# Build and push each image (ARM64)
echo "==> Building Loki..."
docker buildx build --platform linux/arm64 -t ${REGISTRY}/obs-monitoring-loki:latest \
  -f ${CONFIGS_DIR}/loki/Dockerfile ${CONFIGS_DIR}/loki/ --push

echo "==> Building Tempo..."
docker buildx build --platform linux/arm64 -t ${REGISTRY}/obs-monitoring-tempo:latest \
  -f ${CONFIGS_DIR}/tempo/Dockerfile ${CONFIGS_DIR}/tempo/ --push

echo "==> Building Alloy..."
docker buildx build --platform linux/arm64 -t ${REGISTRY}/obs-monitoring-alloy:latest \
  -f ${CONFIGS_DIR}/alloy/Dockerfile ${CONFIGS_DIR}/alloy/ --push

echo "==> Building Grafana..."
docker buildx build --platform linux/arm64 -t ${REGISTRY}/obs-monitoring-grafana:latest \
  -f ${CONFIGS_DIR}/grafana/Dockerfile ${CONFIGS_DIR}/grafana/ --push

echo "==> All images built and pushed successfully!"
