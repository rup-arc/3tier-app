# GitHub Actions Setup for ECR & EKS Deployment

## Step 1: Create GitHub Secrets

Add these secrets to your GitHub repository (Settings > Secrets and variables > Actions):

```
AWS_ROLE_ARN: arn:aws:iam::YOUR_AWS_ACCOUNT_ID:role/GitHubActionsRole
```

## Step 2: Create IAM Role for GitHub Actions

Run in AWS CLI:

```bash
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create trust policy for GitHub
cat > /tmp/trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_ORG/3tier-app:ref:refs/heads/main"
        }
      }
    }
  ]
}
EOF

# Create role
aws iam create-role \
  --role-name GitHubActionsRole \
  --assume-role-policy-document file:///tmp/trust-policy.json

# Create policy for ECR + EKS
cat > /tmp/github-actions-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:DescribeImages",
        "ecr:BatchDeleteImage"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "eks:DescribeCluster",
        "eks:ListClusters"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sts:GetCallerIdentity"
      ],
      "Resource": "*"
    }
  ]
}
EOF

# Attach policy to role
aws iam put-role-policy \
  --role-name GitHubActionsRole \
  --policy-name GitHubActionsPolicy \
  --policy-document file:///tmp/github-actions-policy.json

echo "AWS_ROLE_ARN: arn:aws:iam::${AWS_ACCOUNT_ID}:role/GitHubActionsRole"
```

Copy the `AWS_ROLE_ARN` output and add it as a GitHub secret.

## Step 3: Create ECR Repositories

```bash
AWS_REGION="ap-south-1"

aws ecr create-repository \
  --repository-name 3tier-app/backend \
  --region $AWS_REGION

aws ecr create-repository \
  --repository-name 3tier-app/frontend \
  --region $AWS_REGION
```

## Step 4: Initial Manual Build & Push (Bootstrap)

```bash
AWS_REGION="ap-south-1"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $ECR_REGISTRY

# Build and push backend
cd /home/vboxuser/3tier-app/backend
docker build -t 3tier-app/backend:v1.0 .
docker tag 3tier-app/backend:v1.0 $ECR_REGISTRY/3tier-app/backend:v1.0
docker push $ECR_REGISTRY/3tier-app/backend:v1.0

# Build and push frontend
cd /home/vboxuser/3tier-app/frontend
docker build -t 3tier-app/frontend:v1.0 .
docker tag 3tier-app/frontend:v1.0 $ECR_REGISTRY/3tier-app/frontend:v1.0
docker push $ECR_REGISTRY/3tier-app/frontend:v1.0
```

## Step 5: Deploy Initial Version to EKS

```bash
# Update kubeconfig
aws eks update-kubeconfig --name 3tier-app-cluster --region ap-south-1

# Update deployments with ECR image URIs
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com"

sed -i "s|3tier-app-backend:latest|$ECR_REGISTRY/3tier-app/backend:v1.0|g" k8s/backend-deployment.yaml
sed -i "s|3tier-app-frontend:latest|$ECR_REGISTRY/3tier-app/frontend:v1.0|g" k8s/frontend-deployment.yaml

# Apply to K8s
kubectl apply -f k8s/backend-secret.yaml
kubectl apply -f k8s/backend-config.yaml
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/backend-service.yaml
kubectl apply -f k8s/frontend-deployment.yaml
kubectl apply -f k8s/frontend-service.yaml
kubectl apply -f k8s/ingress.yaml

# Verify deployment
kubectl get pods -A
kubectl get svc -A
kubectl rollout status deployment/backend-deployment
kubectl rollout status deployment/frontend-deployment
```

## Step 6: How the Workflow Works

1. **Trigger**: Push to `main` with changes in `backend/` or `frontend/` directories
2. **Security Scans**: Gitleaks + Trivy run first
3. **Change Detection**: Checks if Docker files actually changed
4. **Build & Push**: Only builds/pushes if changed
   - Generates unique tags: `v1.0-{commit-short-sha}-{timestamp}`
   - Pushes `latest` tag as well
5. **Clean Old Images**: Keeps only the 3 latest images in ECR
6. **Update K8s**: Updates deployment YAML with new image URI
7. **Deploy with Rolling Update**: 
   - No downtime (maxUnavailable: 0)
   - One extra pod spins up (maxSurge: 1)
   - Old pods terminate after new ones are healthy
8. **Verify**: Waits for rollout to complete before marking success

## Step 7: Testing

1. Make a code change in `backend/` or `frontend/`
2. Commit and push to `main`
3. Watch the workflow in GitHub Actions tab
4. Check pod logs: `kubectl logs -f deployment/backend-deployment`
5. Verify endpoints are responding

## Rollback if Needed

```bash
# Rollback to previous version
kubectl rollout undo deployment/backend-deployment
kubectl rollout undo deployment/frontend-deployment

# View rollout history
kubectl rollout history deployment/backend-deployment
```
