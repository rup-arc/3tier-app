# 3-Tier App Deployment - Complete Checklist

## ✅ COMPLETED

### Infrastructure (Terraform)
- ✅ EKS cluster with Fargate (3tier-app-cluster)
- ✅ RDS PostgreSQL (rds-threetierapp.c6trbbvkk8oj.ap-south-1.rds.amazonaws.com)
- ✅ VPC, subnets, security groups
- ✅ All credentials configured (username: postgres, password: Rupam127xyz)

### Kubernetes Configuration
- ✅ backend-secret.yaml - Updated with RDS credentials
- ✅ backend-config.yaml - Configured with DB settings & CORS
- ✅ backend-deployment.yaml - Rolling update strategy added
- ✅ frontend-deployment.yaml - Rolling update strategy added
- ✅ backend/app/config/db.config.js - Reads environment variables
- ✅ All K8s manifests ready for deployment

### Docker Files
- ✅ backend/Dockerfile - Ready
- ✅ frontend/Dockerfile - Ready

### GitHub Actions CI/CD
- ✅ Created `.github/workflows/ecr-deploy.yml` with:
  - Gitleaks security scan
  - Trivy vulnerability scan
  - Docker change detection
  - ECR image build & push
  - Automatic version tagging (v1.0-{commit-sha}-{timestamp})
  - Old image cleanup (keeps 3 latest)
  - K8s deployment with rolling updates
  - Zero-downtime deployment strategy

---

## 📋 NEXT STEPS - Execute in Order

### Phase 1: Bootstrap ECR & Initial Deployment (Today)

**Step 1: Create AWS IAM Role for GitHub Actions**
```bash
# Run commands from GITHUB_ACTIONS_SETUP.md section "Step 2"
# This creates GitHubActionsRole and outputs AWS_ROLE_ARN
```

**Step 2: Add GitHub Secret**
- Go to: https://github.com/YOUR_ORG/3tier-app/settings/secrets/actions
- Click "New repository secret"
- Name: `AWS_ROLE_ARN`
- Value: `arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActionsRole` (from Step 1)

**Step 3: Create ECR Repositories**
```bash
# Run commands from ECR_SETUP.md or GITHUB_ACTIONS_SETUP.md "Step 3"
aws ecr create-repository --repository-name 3tier-app/backend --region ap-south-1
aws ecr create-repository --repository-name 3tier-app/frontend --region ap-south-1
```

**Step 4: Manual Build & Push to ECR**
```bash
# Run commands from GITHUB_ACTIONS_SETUP.md "Step 4"
# This builds and pushes v1.0 images to ECR
```

**Step 5: Deploy to EKS**
```bash
# Run commands from GITHUB_ACTIONS_SETUP.md "Step 5"
# This applies all K8s manifests and deploys the app
```

**Step 6: Verify Deployment**
```bash
kubectl get pods -A
kubectl get svc -A
kubectl logs -f deployment/backend-deployment
kubectl logs -f deployment/frontend-deployment
```

---

### Phase 2: GitHub Actions Automation (After Initial Deployment)

From this point forward:

1. **Make code changes** to `backend/` or `frontend/`
2. **Commit and push** to `main` branch
3. **Workflow automatically**:
   - Scans code for security issues
   - Detects if Docker changed
   - Builds new image with unique tag
   - Pushes to ECR
   - Deletes old ECR images (keeps 3)
   - Updates K8s deployment with new image
   - Deploys with rolling updates (zero downtime)
   - Verifies pods are running

4. **Monitor in GitHub**:
   - Go to Actions tab
   - Watch workflow progress
   - View logs for any issues

---

## 🔄 How Zero-Downtime Deployment Works

```
Before: 2 backend pods running v1.0
Push changes to main
├─ New pod spins up with v1.1 (maxSurge: 1)
├─ v1.1 pod passes health checks
├─ v1.0 pod 1 terminates gracefully
├─ v1.1 pod 2 spins up
├─ v1.0 pod 2 terminates gracefully
After: 2 backend pods running v1.1 (never had 0 pods)
```

**Key settings in K8s deployments:**
- `maxSurge: 1` - Allow 1 extra pod temporarily
- `maxUnavailable: 0` - Never stop all pods
- `readinessProbe` - Only send traffic to healthy pods
- `livenessProbe` - Restart unhealthy pods

---

## 📊 Current Architecture

```
GitHub Push
    ↓
GitHub Actions Workflow
    ├─ Security Scans (Gitleaks, Trivy)
    ├─ Change Detection
    ├─ Build Docker Image
    ├─ Push to ECR
    └─ Update K8s & Deploy
    ↓
EKS Cluster (Fargate)
    ├─ Backend Deployment (2 replicas)
    │   └─ Connects to RDS PostgreSQL
    ├─ Frontend Deployment (2 replicas)
    │   └─ Communicates with Backend
    ├─ Services (ClusterIP for internal, LoadBalancer for external)
    └─ Ingress (If configured)
    ↓
RDS PostgreSQL
    └─ Data persistence
```

---

## 🚀 Quick Reference Commands

```bash
# View pod status
kubectl get pods -A

# View services
kubectl get svc -A

# View deployments
kubectl get deployment -A

# View logs
kubectl logs -f deployment/backend-deployment
kubectl logs -f deployment/frontend-deployment

# Check rollout status
kubectl rollout status deployment/backend-deployment
kubectl rollout status deployment/frontend-deployment

# Describe deployment (see image, env vars, etc)
kubectl describe deployment/backend-deployment

# Scale replicas
kubectl scale deployment/backend-deployment --replicas=3

# Rollback to previous version
kubectl rollout undo deployment/backend-deployment

# View ECR images
aws ecr describe-images --repository-name 3tier-app/backend --region ap-south-1

# Delete old ECR images
aws ecr batch-delete-image \
  --repository-name 3tier-app/backend \
  --image-ids imageTag=v1.0-abc123-1234567 \
  --region ap-south-1
```

---

## ⚠️ Troubleshooting

### Pods stuck in ImagePullBackOff
```bash
kubectl describe pod <pod-name>
# Check if ECR image URI is correct in deployment YAML
# Verify AWS credentials/IAM permissions
```

### No connectivity between services
```bash
# Check if secrets are mounted
kubectl get secret backend-secret -o yaml
kubectl describe deployment/backend-deployment | grep "Mounts" -A 10

# Check if backend can reach RDS
kubectl exec -it <backend-pod> -- bash
# Inside pod: nc -zv rds-threetierapp.c6trbbvkk8oj.ap-south-1.rds.amazonaws.com 5432
```

### Deployment not updating with new image
```bash
# Force re-pull
kubectl set image deployment/backend-deployment \
  backend=<NEW_ECR_IMAGE_URI> \
  --record

# Or delete pods to trigger new deployment
kubectl delete pod -l app=backend
```

---

## 📝 Files Created/Modified

**New Files:**
- `.github/workflows/ecr-deploy.yml` - Complete CI/CD workflow
- `ECR_SETUP.md` - ECR repository setup guide
- `GITHUB_ACTIONS_SETUP.md` - Complete GitHub Actions setup guide

**Modified Files:**
- `k8s/backend-secret.yaml` - Updated with RDS credentials
- `k8s/backend-config.yaml` - Updated CORS_ORIGIN to "*"
- `k8s/backend-deployment.yaml` - Added rolling update strategy
- `k8s/frontend-deployment.yaml` - Added rolling update strategy

---

## ✨ Features of the Solution

✅ **Smart Change Detection** - Only builds if Docker files changed
✅ **Automatic Versioning** - Unique tags with commit SHA & timestamp
✅ **Image Cleanup** - Automatically deletes old ECR images (keeps 3)
✅ **Zero-Downtime Deployment** - Rolling updates, no service interruption
✅ **Health Checks** - Readiness & liveness probes
✅ **Security Scanning** - Gitleaks + Trivy before deployment
✅ **OIDC Authentication** - No hardcoded AWS credentials
✅ **Artifact Management** - Updated K8s configs passed between jobs
✅ **Rollback Capability** - Easy rollback to previous versions
✅ **Visibility** - Comprehensive logging and status checks

---

## 🎯 Timeline to Completion

| Phase | Task | Estimated Time |
|-------|------|-----------------|
| 1 | Create IAM Role | 5 min |
| 2 | Add GitHub Secret | 2 min |
| 3 | Create ECR Repos | 2 min |
| 4 | Build & Push Images | 10 min |
| 5 | Deploy to K8s | 5 min |
| 6 | Verify Deployment | 5 min |
| **Total** | **Initial Setup** | **~30 min** |
| - | Future Pushes | 3-5 min (automatic) |

---

## 🎉 After This is Done

Once the initial deployment is verified:
1. All future code pushes to `main` automatically:
   - Build & test
   - Scan for security
   - Deploy to EKS with zero downtime
2. Monitor in GitHub Actions tab
3. App updates automatically without manual intervention

**You're done! The 3-tier app is now fully automated on AWS EKS with CI/CD! 🚀**
