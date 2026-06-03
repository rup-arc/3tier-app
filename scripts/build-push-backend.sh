#!/bin/bash

# Backend build and push script
set -e

AWS_REGION=${AWS_REGION:-"ap-south-1"}
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
IMAGE_NAME="3tier-app/backend"
IMAGE_TAG="${1:-v1.0}"

echo "Building and pushing backend image..."
echo "AWS Account: $AWS_ACCOUNT_ID"
echo "Registry: $REGISTRY"
echo "Image: $IMAGE_NAME:$IMAGE_TAG"

# Login to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $REGISTRY

# Build image
echo "Building Docker image..."
cd "$(dirname "$0")/../backend"
docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .

# Tag image for ECR
docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}

# Push to ECR
echo "Pushing image to ECR..."
docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}

echo "✓ Backend image successfully pushed to ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
