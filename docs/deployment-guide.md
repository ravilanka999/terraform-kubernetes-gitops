# Deployment Guide

Complete guide to deploying the Terraform Kubernetes GitOps Platform.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Infrastructure Deployment](#infrastructure-deployment)
3. [GitOps Configuration](#gitops-configuration)
4. [Application Deployment](#application-deployment)
5. [Verification](#verification)
6. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Tools

| Tool | Version | Purpose |
|------|---------|---------|
| [Terraform](https://developer.hashicorp.com/terraform/downloads) | >= 1.0 | Infrastructure as Code |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | Matching cluster version | Kubernetes CLI |
| [Helm](https://helm.sh/docs/intro/install/) | >= 3.0 | Package management |
| [Argo CD CLI](https://argo-cd.readthedocs.io/en/stable/cli_installation/) | Optional | GitOps management |
| [AWS CLI](https://aws.amazon.com/cli/) | Latest | AWS interactions |
| [jq](https://stedolan.github.io/jq/download/) | Optional | JSON processing |
| [yq](https://mikefarah.gitbook.io/yq/) | Optional | YAML processing |

### AWS Setup

1. **Create AWS Account** (if you don't have one)
2. **Configure AWS CLI**:
   ```bash
   aws configure
   # Enter: Access Key, Secret Key, region (ap-southeast-2), output format (json)
   ```
3. **Create IAM User/Programmatic Access** with permissions:
   - AmazonEKSClusterPolicy
   - AmazonEKSWorkerNodePolicy
   - AmazonEC2ContainerRegistryReadOnly
   - AmazonVPCFullAccess
   - AmazonEKSVPCResourceController
   - AmazonEBSFullAccess
   - IAMFullAccess (for creating roles)

---

## Infrastructure Deployment

### Step 1: Prepare Remote State

**Create S3 bucket for Terraform state:**
```bash
aws s3api create-bucket \
  --bucket terraform-state-gitops-demo-ap-southeast-2 \
  --region ap-southeast-2 \
  --create-bucket-configuration LocationConstraint=ap-southeast-2

aws s3api put-bucket-versioning \
  --bucket terraform-state-gitops-demo-ap-southeast-2 \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket terraform-state-gitops-demo-ap-southeast-2 \
  --server-side-encryption-configuration '{
    "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
  }'
```

**Create DynamoDB table for state locking:**
```bash
aws dynamodb create-table \
  --table-name terraform-locks-gitops-demo \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

### Step 2: Update Backend Configuration

Edit `infrastructure/backend.tf`:
```hcl
bucket         = "terraform-state-gitops-demo-ap-southeast-2"  # Your bucket name
region         = "ap-southeast-2"
dynamodb_table = "terraform-locks-gitops-demo"
```

### Step 3: Configure Variables

Copy and edit `infrastructure/terraform.tfvars.example`:
```bash
cp infrastructure/terraform.tfvars.example infrastructure/terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
aws_region      = "ap-southeast-2"
project_name    = "gitops-demo"
environment     = "dev"
# ... other variables
```

**Important notes:**
- For production, use stronger security groups
- Change `enable_cluster_creator_admin = false` after initial setup
- Consider using spot instances for cost savings in non-prod

### Step 4: Initialize and Apply Terraform

```bash
# Navigate to infrastructure directory
cd infrastructure

# Initialize Terraform (downloads providers, configures backend)
terraform init

# Review the plan
terraform plan -var-file="terraform.tfvars"

# Apply (creates VPC, EKS, etc.)
terraform apply -var-file="terraform.tfvars"
```

**This takes 15-30 minutes** (EKS cluster provisioning is slow).

### Step 5: Configure kubectl

After EKS is created, configure your local kubeconfig:

```bash
# Option 1: Using AWS CLI (requires AWS credentials)
aws eks update-kubeconfig \
  --region ap-southeast-2 \
  --name gitops-eks  # Use your cluster name from terraform output

# Option 2: Get kubeconfig from Terraform output
terraform output kubeconfig
# Then manually update ~/.kube/config

# Verify connection
kubectl get nodes
```

---

## GitOps Configuration

### Step 1: Install Argo CD

If you don't have Argo CD installed:

```bash
# Create argocd namespace
kubectl create namespace argocd

# Install Argo CD (stable manifests)
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods to be ready
kubectl get pods -n argocd
```

### Step 2: Access Argo CD UI

Get the initial admin password:
```bash
kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Expose the service:
```bash
# Option A: Port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Now open http://localhost:8080 in browser
# Login with username: admin, password: (from above)

# Option B: LoadBalancer (if you have ingress controller)
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
```

### Step 3: Deploy App of Apps

Apply the root Argo CD application:

```bash
# Apply the AppProject first
kubectl apply -f argocd/app-of-apps.yaml

# Apply the root application
kubectl apply -f argocd/app-of-apps.yaml  # This includes both project and root app
```

Wait a minute - Argo CD will detect the Application CRD and start syncing.

---

## Application Deployment

### Option A: Via Argo CD (Recommended)

Argo CD automatically deploys:
1. Namespaces (dev, prod, argocd)
2. Infrastructure manifests (StorageClass)
3. Demo application (via Kustomize overlays)

**Manual sync** if auto-sync isn't enabled:
```bash
argocd app sync gitops-platform-root  # Sync root (triggers all children)
argocd app list  # See status
argocd app wait demo-app-dev  # Wait for sync to complete
```

**View in UI:** http://localhost:8080 (or your Argo CD URL)

### Option B: Direct kubectl/Kustomize (for testing)

```bash
# Deploy to dev
make kube-apply-dev

# Deploy to prod
make kube-apply-prod

# Verify
kubectl get pods -n dev
kubectl get hpa -n dev

# View logs
kubectl logs -f -n dev -l app=demo-app
```

### Option C: Via Helm

```bash
# Add repo
helm repo add demo-app ./helm-charts/demo-app

# Install to dev
make helm-install-dev

# Check status
helm list -n dev
kubectl get pods -n dev

# Upgrade
make helm-upgrade-dev

# Uninstall
make helm-uninstall-dev
```

---

## Verification

### Check Infrastructure

```bash
# Terraform outputs
cd infrastructure
terraform output

# Should show:
# - VPC ID, Subnet IDs
# - EKS cluster name, endpoint
# - Node IAM role ARN
```

### Check Kubernetes Cluster

```bash
# Nodes
kubectl get nodes -o wide
# Should see 2+ worker nodes in Ready state

# Namespaces
kubectl get ns
# Should see: default, kube-system, dev, prod, argocd

# EKS addons
kubectl get addons -n eks-system  # or check AWS console
```

### Check Argo CD

```bash
# Applications
argocd app list
# Should see:
# - gitops-platform-root (Synced)
# - namespaces (Synced)
# - infra-apps (Synced)
# - demo-app-dev (Synced)
# - demo-app-prod (if deployed)

# Sync status
argocd app status demo-app-dev
```

### Check Application

```bash
# Pods
kubectl get pods -n dev

# Services
kubectl get svc -n dev
demo-app   ClusterIP   ...

# HPA
kubectl get hpa -n dev
demo-app   2/3   CPU: 5%    Memory: 10%

# Access the app (if Service type is LoadBalancer)
kubectl get svc demo-app -n dev -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
# Then curl that hostname

# Or port-forward for testing
kubectl port-forward svc/demo-app 8080:80 -n dev
# Then open http://localhost:8080

# Check logs
kubectl logs -f deployment/demo-app -n dev

# Health endpoint
kubectl exec -it deploy/demo-app -n dev -- curl http://localhost:8080/health
```

---

## Environment-Specific Configurations

### Development (`overlays/dev/`)
- **Replicas:** 2 (can scale to 1 for cost savings)
- **HPA:** Max 3 replicas, CPU threshold 80%
- **Probes:** Standard delays (30s start)
- **Image:** Generic test images (nginx:alpine)
- **Access:** ClusterIP only (internal)
- **Logging:** Debug level
- **Auto-sync:** Enabled, prune=false for safety

### Production (`overlays/prod/`)
- **Replicas:** 3 minimum
- **HPA:** Max 10 replicas, CPU threshold 60%
- **Probes:** Faster timeouts (2-3s) for quick failure detection
- **Image:** Pinned versions, can use private ECR
- **Access:** LoadBalancer service with AWS NLB
- **Security:** Non-root mandatory, capabilities dropped
- **Logging:** WARN level only
- **Monitoring:** ServiceMonitor enabled for Prometheus
- **Auto-sync:** Enabled, prune=true (consider manual approvals)

---

## Making Changes

### Infrastructure changes (Terraform)

```bash
cd infrastructure
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

### Application changes (K8s manifests)

```bash
# Edit files in kubernetes/base/ or overlays/

# Deploy via kubectl
kubectl apply -k kubernetes/overlays/dev

# Or commit and let Argo CD auto-sync
git add .
git commit -m "feat: update deployment resource limits"
git push

# Argo CD will detect change and sync automatically
```

### Helm chart changes

```bash
cd helm-charts/demo-app
# Edit values.yaml or templates/

# Test locally
helm install demo-test ./ --namespace dev --values values-dev.yaml --dry-run

# Commit and push (Argo CD syncs)

# Or manually upgrade
helm upgrade demo-app ./ -n dev --values values-dev.yaml
```

---

## Rollbacks

### Terraform Rollback

```bash
cd infrastructure
terraform state list  # See current resources
terraform apply -var-file="terraform.tfvars" -target=<resource>  # Partial apply
# Or use terraform workspace to switch to previous state
```

### Kubernetes Rollback (Kustomize)

```bash
# View git history
git log --oneline kubernetes/overlays/prod/

# Checkout previous version
git checkout <commit-hash>

# Apply old version
kubectl apply -k kubernetes/overlays/prod

# Return to latest
git checkout main
```

### Helm Rollback

```bash
helm history demo-app -n prod
helm rollback demo-app 1 -n prod  # Rollback to revision 1
```

### Argo CD Rollback

```bash
# Via UI: App history → Rollback
# Via CLI:
argocd app history demo-app-prod
argocd app rollback demo-app-prod <revision>
```

---

## Cost Optimization Tips

1. **Use Spot Instances for Dev:**
   ```hcl
   capacity_type = "SPOT"  # in eks module
   ```

2. **Scale Down Dev at Night:**
   ```bash
   kubectl scale deployment demo-app --replicas=0 -n dev
   # Or use K8s CronJob for automatic scaling
   ```

3. **Right-Size Instances:** Monitor with CloudWatch and adjust `eks_node_instance_type`

4. **EKS Savings Plans:** Purchase 1-year or 3-year commitment for 40-60% discount

5. **Delete Unused Resources:**
   ```bash
   terraform destroy -var-file="terraform.tfvars"  # To clean up demo
   ```

6. **Argo CD Retention:** Configure shorter history if using many apps:
   ```bash
   kubectl patch argocd-cm -n argocd -p '{"data": {"resource.exclusions": "*"}}'
   ```

---

## Clean Up

To completely remove the infrastructure:

```bash
# 1. Delete Argo CD applications
kubectl delete -f argocd/applications/  # or delete individually
kubectl delete -f argocd/app-of-apps.yaml

# 2. Delete Argo CD installation
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
# Or: kubectl delete ns argocd

# 3. Destroy Terraform infrastructure
cd infrastructure
terraform destroy -var-file="terraform.tfvars"

# 4. Delete remote state (optional)
# aws s3 rm s3://terraform-state-... --recursive
# aws dynamodb delete-table --table-name terraform-locks-...

# 5. Delete local files
rm -rf infrastructure/.terraform
rm -rf .terraform
```

---

## Support

- **Terraform AWS Modules:** https://registry.terraform.io/modules/terraform-aws-modules
- **Argo CD Docs:** https://argo-cd.readthedocs.io/
- **EKS Best Practices:** https://aws.github.io/aws-eks-best-practices/
- **GitHub Issues:** Create issue in this repository

---

**Next Steps:**
- Add monitoring (Prometheus, Grafana)
- Set up CI/CD pipelines (GitHub Actions, Jenkins)
- Configure alerting (PagerDuty, Slack)
- Implement disaster recovery (Velero, cluster backups)
