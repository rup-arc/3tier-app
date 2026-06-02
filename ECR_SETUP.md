# ECR Setup Instructions

Run these commands once to create ECR repositories:

```bash
AWS_REGION="ap-south-1"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create ECR repository for backend
aws ecr create-repository \
  --repository-name 3tier-app/backend \
  --region $AWS_REGION

# Create ECR repository for frontend
aws ecr create-repository \
  --repository-name 3tier-app/frontend \
  --region $AWS_REGION

# Enable image scanning and tag mutability (optional)
aws ecr put-image-scanning-configuration \
  --repository-name 3tier-app/backend \
  --image-scanning-configuration scanOnPush=true \
  --region $AWS_REGION

aws ecr put-image-scanning-configuration \
  --repository-name 3tier-app/frontend \
  --image-scanning-configuration scanOnPush=true \
  --region $AWS_REGION

# Get login token and push images
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Build backend
cd /home/vboxuser/3tier-app/backend
docker build -t 3tier-app/backend:v1.0 .
docker tag 3tier-app/backend:v1.0 $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/3tier-app/backend:v1.0
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/3tier-app/backend:v1.0

# Build frontend
cd /home/vboxuser/3tier-app/frontend
docker build -t 3tier-app/frontend:v1.0 .
docker tag 3tier-app/frontend:v1.0 $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/3tier-app/frontend:v1.0
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/3tier-app/frontend:v1.0
```

After pushing, update the K8s deployment files with the image URIs from ECR.
