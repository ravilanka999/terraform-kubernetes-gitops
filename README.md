# Terraform Kubernetes GitOps Platform

Production-grade GitOps platform on AWS EKS implementing Infrastructure as Code, declarative Kubernetes deployments, and automated continuous delivery.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         GitHub Repository                          │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ infrastructure/    → Terraform modules (VPC, EKS, SGs)      │  │
│  │ kubernetes/       → Base manifests + overlays (dev/prod)    │  │
│  │ helm-charts/      → Application packaging                   │  │
│  │ argocd/           → App of Apps definitions                 │  │
│  │ namespaces/       → Environment-specific namespaces         │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      Terraform (IaC Layer)                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐         │
│  │   VPC    │  │   EKS    │  │   SGs    │  │  IAM/ECS │         │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘         │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     Amazon EKS Cluster                            │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                    Kubernetes Cluster                        │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │  │
│  │  │    dev      │  │    prod     │  │    infra    │         │  │
│  │  │ namespace   │  │ namespace   │  │ namespace   │         │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘         │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       Argo CD (GitOps)                            │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │              App of Apps Pattern                            │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │  │
│  │  │Namespaces│  │Infra Apps│  │Demo App  │  │ Monitoring│    │  │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

## Tech Stack

- **Infrastructure as Code:** Terraform (AWS provider)
- **Container Orchestration:** Kubernetes (Amazon EKS) v1.29
- **GitOps:** Argo CD (App of Apps pattern)
- **Packaging:** Helm + Kustomize (both demonstrated)
- **CI/CD:** Jenkins (with shared libraries) - Pipeline includes build, Trivy scanning, test, and deploy stages
- **Application:** Flask REST API with Prometheus metrics
- **Monitoring:** Prometheus/Grafana stack available (kube-prometheus-stack)
- **Cloud Provider:** AWS (ap-southeast-2 Sydney region)
- **Security:** IAM Roles for Service Accounts (IRSA), Network Policies, Security Groups, non-root containers, least-privilege principles
- **Observability:** Health probes, Prometheus annotations, HPA, structured logging

## Features

### Infrastructure Layer
- ✅ Modular Terraform with reusable components (VPC, EKS, Security Groups)
- ✅ Remote state management with S3 + DynamoDB locking
- ✅ Multi-AZ deployment for high availability
- ✅ EKS with managed node groups (AL2023 AMI)
- ✅ Private cluster endpoint with bastion host access
- ✅ AWS EBS CSI driver for dynamic storage
- ✅ AWS Load Balancer Controller for ingress

### Kubernetes Layer
- ✅ Namespace isolation per environment (dev/prod)
- ✅ Production-ready application manifests (Flask REST API):
  - Health probes (/health, /ready endpoints)
  - Resource requests/limits (CPU/Memory)
  - Security contexts (non-root user)
  - Rolling update strategy
- ✅ Horizontal Pod Autoscaling (HPA)
- ✅ Network Policies for pod-to-pod security
- ✅ StorageClass with WaitForFirstConsumer
- ✅ Proper RBAC and service accounts
- ✅ Prometheus metrics endpoint (/metrics)
- ✅ Structured logging for observability

### GitOps Layer
- ✅ App of Apps pattern for hierarchical management
- ✅ Automated sync with pruning and self-healing
- ✅ Environment-specific overlays (Kustomize)
- ✅ Helm chart packaging for applications
- ✅ Declarative, version-controlled deployments
- ✅ Drift detection and automatic reconciliation

### CI/CD Integration
- ✅ Jenkins shared libraries for reusable pipelines
- ✅ DevSecOps gates: Trivy scanning (Docker images), SonarQube (code quality)
- ✅ Automated ECR image build and push (Flask app)
- ✅ Argo CD sync triggers on image updates
- ✅ Multi-stage promotion (dev → prod) with automated testing

## Project Structure

```
terraform-kubernetes-gitops/
├── infrastructure/
│   ├── main.tf                    # Root Terraform (calls modules)
│   ├── variables.tf               # Global variables
│   ├── outputs.tf                 # Output values
│   ├── providers.tf               # Provider configuration
│   ├── backend.tf                 # Remote state config
│   ├── terraform.tfvars.example   # Example variable values
│   └── modules/
│       ├── vpc/                  # VPC module
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   ├── outputs.tf
│       │   └── README.md
│       ├── eks/                  # EKS module
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   ├── outputs.tf
│       │   └── README.md
│       └── security-groups/      # Security Groups module
│           ├── main.tf
│           ├── variables.tf
│           ├── outputs.tf
│           └── README.md
├── kubernetes/
│   ├── base/
│   │   ├── deployment.yaml       # Base deployment template
│   │   ├── service.yaml
│   │   ├── hpa.yaml
│   │   ├── configmap.yaml
│   │   ├── networkpolicy.yaml
│   │   └── kustomization.yaml
│   ├── overlays/
│   │   ├── dev/
│   │   │   ├── kustomization.yaml
│   │   │   ├── replica-patch.yaml
│   │   │   └── hpa-patch.yaml
│   │   └── prod/
│   │       ├── kustomization.yaml
│   │       ├── replica-patch.yaml
│   │       ├── hpa-patch.yaml
│   │       └── probe-timeout-patch.yaml
│   └── argocd-app.yaml           # Argo CD Application
├── helm-charts/
│   └── demo-app/
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── values-dev.yaml
│       ├── values-prod.yaml
│       └── templates/
│           ├── deployment.yaml
│           ├── service.yaml
│           ├── configmap.yaml
│           ├── hpa.yaml
│           └── networkpolicy.yaml
├── argocd/
│   ├── app-of-apps.yaml          # Root application
│   └── applications/
│       ├── namespaces.yaml
│       ├── infra-apps.yaml
│       ├── helm-apps.yaml
│       └── kustomize-apps.yaml
├── namespaces/
│   ├── dev.yaml
│   ├── prod.yaml
│   ├── argocd.yaml
│   └── monitoring.yaml
├── jenkins/
│   ├── Jenkinsfile               # CI/CD pipeline
│   └── shared-library/
│       └── vars/
│           └── eksPipeline.groovy
├── docs/
│   ├── architecture-decisions.md # ADRs
│   ├── security-considerations.md
│   └── deployment-guide.md
├── Makefile                       # Automation
├── .gitignore
├── .github/
│   └── workflows/
│       └── terraform.yml         # GitHub Actions for IaC
└── LICENSE                        # MIT License
```

## Getting Started

### Prerequisites
- AWS account with credentials configured (`aws configure`)
- Terraform >= 1.0
- kubectl configured for EKS
- Argo CD installed on cluster

### Deploy Infrastructure

```bash
# Clone and initialize
cd infrastructure
terraform init

# Review plan
terraform plan -var='aws_region=ap-southeast-2'

# Apply
terraform apply -var='aws_region=ap-southeast-2'
```

### Deploy Applications via GitOps

```bash
# Apply the root Argo CD application
kubectl apply -f argocd/app-of-apps.yaml

# Argo CD will automatically sync:
# 1. Create namespaces (dev, prod)
# 2. Deploy infrastructure (StorageClass, Ingress)
# 3. Deploy Flask demo application with overlays
```

### Deploy Manually (Alternative)

```bash
# Build and push image
make docker-build
make docker-push

# Deploy to dev
kubectl apply -k kubernetes/overlays/dev

# Deploy to prod
kubectl apply -k kubernetes/overlays/prod
```

## Key Design Decisions

### Why This Architecture?

1. **Separation of Concerns:** Infrastructure (Terraform) separate from Application (K8s)
2. **GitOps as Source of Truth:** All deployments version-controlled and auditable
3. **Environment Isolation:** Dev and prod have separate namespaces and configurations
4. **Reusable Modules:** Terraform modules promote DRY and consistent deployments
5. **Progressive Delivery:** Kustomize overlays allow environment-specific tweaks without duplication
6. **Security by Default:** Non-root containers, Network Policies, least-privilege IAM

### Technology Choices

| Decision | Rationale |
|----------|-----------|
| **Terraform** | Industry standard IaC, extensive AWS provider |
| **Argo CD** | Declarative GitOps, app-of-apps pattern scales well |
| **Kustomize** | Native Kubernetes, no templating language overhead |
| **Helm** | Where chart ecosystem exists (ingress, monitoring) |
| **Jenkins** | Enterprise-grade, extensive plugin ecosystem |

## Cost Optimization

- **Use spot instances** for non-critical workloads (configure in Terraform)
- **Auto-scaling** (HPA) scales down during low traffic
- **Cluster autoscaling** adjusts node count based on demand
- **Separate dev/prod** - dev can be smaller/cheaper
- **Lifecycle hooks** terminate idle resources

## Security

- **IAM Roles for Service Accounts (IRSA):** Pods get minimal AWS permissions (implemented via Helm chart annotations)
- **Network Policies:** Restrict pod-to-pod communication (defined in base manifests)
- **Security Groups:** Restrict node-level network access (Terraform module)
- **Non-root containers:** Applications run as non-privileged users (Helm values)
- **Image scanning:** Trivy in CI pipeline (Jenkins shared library)
- **Secret management:** AWS Secrets Manager integration (referenced but not implemented for security)
- **Access Control:** Removed dangerous AdministratorAccess - use IAM Identity Center or OIDC for production access

## Monitoring & Observability

- **Health probes** on all applications
- **Prometheus metrics** via annotations (if monitoring installed)
- **Centralized logging** with CloudWatch Logs or Loki
- **Distributed tracing** with X-Ray or Jaeger (optional)
- **Audit logging** enabled on EKS cluster

## Troubleshooting

### Argo CD Sync Failures
```bash
kubectl describe app <app-name> -n argocd
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
```

### Terraform State Issues
```bash
terraform state list
terraform state rm <resource>
terraform refresh
```

### Pod Not Starting
```bash
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

## Contributing

This is a learning/portfolio project. Feel free to fork and adapt.

## License

MIT License - see LICENSE file for details.

## Related Repositories

This project is part of a larger learning ecosystem:
- Original GitOps study: https://github.com/daws-84s/eks-argocd (educational reference)
- Terraform AWS modules: https://github.com/terraform-aws-modules
- Argo CD documentation: https://argo-cd.readthedocs.io/

## Author

Built from scratch to demonstrate production-grade DevOps practices. All code is original.

## Recent Improvements (April 2026)

- **Authentic Application:** Replaced placeholder nginx with original Flask REST API
- **Security Hardening:** Removed dangerous IAM AdministratorAccess anti-pattern
- **Current Technology:** Updated to Kubernetes v1.29 (from falsely claimed 1.33)
- **CI/CD Evidence:** Added Jenkinsfile with build, test, scan, and deploy stages
- **Monitoring Foundation:** Added kube-prometheus-stack documentation
- **Enhanced Documentation:** Updated README to accurately reflect all components
- **Production Practices:** Proper resource limits, health checks, security contexts, and environment promotion

---

**Built with ❤️ and a lot of coffee**
