# Terraform Kubernetes GitOps Platform

> A production-grade AWS EKS platform demonstrating end-to-end DevOps engineering — Infrastructure as Code, GitOps continuous delivery, DevSecOps pipelines, and Kubernetes operational best practices.

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-7B42BC?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.29-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![ArgoCD](https://img.shields.io/badge/Argo_CD-GitOps-EF7B4D?logo=argo&logoColor=white)](https://argo-cd.readthedocs.io/)
[![AWS](https://img.shields.io/badge/AWS-EKS-FF9900?logo=amazonaws&logoColor=white)](https://aws.amazon.com/eks/)
[![Jenkins](https://img.shields.io/badge/Jenkins-CI%2FCD-D24939?logo=jenkins&logoColor=white)](https://www.jenkins.io/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## What This Platform Demonstrates

This repository showcases how I design and operate cloud-native infrastructure in a professional DevOps context. The focus is entirely on the **platform layer** — how infrastructure is provisioned, how workloads are deployed, how pipelines enforce quality and security, and how the system stays observable and resilient.

> **Note:** The application workload (a minimal Flask REST API) exists solely as a deployable artefact to exercise the platform. The value here is not the application — it is everything around it.

| Capability | Implementation |
|---|---|
| Infrastructure as Code | Terraform modules (VPC, EKS, Security Groups) with remote state |
| GitOps delivery | Argo CD App of Apps — declarative, self-healing, drift detection |
| Multi-environment | Dev and prod with Kustomize overlays and Helm value overrides |
| CI/CD pipeline | Jenkins Shared Library with DevSecOps gates (Trivy + SonarQube) |
| Security posture | IRSA, least-privilege IAM, Network Policies, non-root containers |
| Observability | Health probes, Prometheus annotations, HPA, structured logging |

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                      GitHub Repository                           │
│               (single source of truth)                           │
│  infrastructure/ │ kubernetes/ │ helm-charts/ │ argocd/ │ jenkins│
└───────────────────────────┬──────────────────────────────────────┘
                            │  push triggers
                            ▼
┌──────────────────────────────────────────────────────────────────┐
│                   Jenkins CI/CD Pipeline                         │
│   Build → Trivy Scan → SonarQube → Terraform Validate → Deploy  │
└───────────────────────────┬──────────────────────────────────────┘
                            │  image push + Argo CD sync
                            ▼
┌──────────────────────────────────────────────────────────────────┐
│                    Terraform  (IaC Layer)                        │
│  VPC (multi-AZ)  │  EKS Managed Node Groups  │  Security Groups  │
│  S3 Remote State │  DynamoDB Locking          │  IAM / IRSA      │
└───────────────────────────┬──────────────────────────────────────┘
                            │  provisions
                            ▼
┌──────────────────────────────────────────────────────────────────┐
│               Amazon EKS Cluster  (ap-southeast-2)               │
│                                                                  │
│  ┌───────────┐    ┌───────────┐    ┌──────────────────────┐     │
│  │    dev    │    │   prod    │    │   infra namespace    │     │
│  │ namespace │    │ namespace │    │  Argo CD │ Monitoring │     │
│  └───────────┘    └───────────┘    └──────────────────────┘     │
│                                                                  │
│      RBAC │ Network Policies │ HPA │ PV/PVC │ Ingress           │
└───────────────────────────┬──────────────────────────────────────┘
                            │  synced by
                            ▼
┌──────────────────────────────────────────────────────────────────┐
│                  Argo CD  —  GitOps Engine                       │
│                    App of Apps Pattern                           │
│   Namespaces │ Infra Apps │ Application (Helm) │ Monitoring      │
│   Auto-sync │ Self-healing │ Pruning │ Drift detection           │
└──────────────────────────────────────────────────────────────────┘
```

---

## Repository Structure

```
terraform-kubernetes-gitops/
│
├── infrastructure/                   # All AWS provisioning via Terraform
│   ├── main.tf                       # Root module
│   ├── variables.tf / outputs.tf
│   ├── backend.tf                    # S3 remote state + DynamoDB lock
│   ├── terraform.tfvars.example
│   └── modules/
│       ├── vpc/                      # Multi-AZ VPC, public/private subnets
│       ├── eks/                      # EKS node groups, IRSA, OIDC
│       └── security-groups/          # Least-privilege SG rules
│
├── kubernetes/                       # Kubernetes manifests
│   ├── base/                         # Reusable base templates
│   │   ├── deployment.yaml           # Non-root, resource-limited, health-probed
│   │   ├── hpa.yaml                  # Horizontal Pod Autoscaler
│   │   ├── networkpolicy.yaml        # Pod-to-pod traffic rules
│   │   └── kustomization.yaml
│   └── overlays/
│       ├── dev/                      # Dev patches (replicas, limits)
│       └── prod/                     # Prod patches (HA, strict probes)
│
├── helm-charts/demo-app/             # Helm packaging with per-env values
│   ├── values.yaml
│   ├── values-dev.yaml
│   ├── values-prod.yaml
│   └── templates/                    # Deployment, Service, HPA, NetworkPolicy
│
├── argocd/                           # GitOps definitions
│   ├── app-of-apps.yaml              # Root application
│   └── applications/
│       ├── namespaces.yaml
│       ├── infra-apps.yaml
│       ├── helm-apps.yaml
│       └── kustomize-apps.yaml
│
├── jenkins/                          # CI/CD
│   ├── Jenkinsfile                   # Multi-stage pipeline
│   └── shared-library/vars/
│       └── eksPipeline.groovy        # Reusable shared library
│
├── namespaces/                       # dev / prod / argocd / monitoring
├── monitoring/                       # kube-prometheus-stack integration
├── docs/
│   ├── architecture-decisions.md     # ADRs
│   ├── security-considerations.md
│   └── deployment-guide.md
├── .github/workflows/terraform.yml   # GitHub Actions — Terraform plan on PR
└── Makefile                          # Convenience targets
```

---

## Infrastructure Deep Dive

### Terraform Modules

Each module is self-contained with its own `variables.tf`, `outputs.tf`, and `README.md`.

**VPC module** provisions a multi-AZ network with public subnets (load balancers), private subnets (worker nodes), NAT Gateways, and proper route tables. All subnet tagging follows EKS conventions for ALB/NLB auto-discovery.

**EKS module** provisions managed node groups using the AL2023 AMI, configures OIDC for IRSA, enables the EBS CSI driver for dynamic storage, and sets up the AWS Load Balancer Controller. The cluster endpoint is private — access is via bastion host only.

**Remote state** uses S3 with versioning and DynamoDB locking to prevent concurrent apply conflicts across team members or pipelines.

### Security Design

| Control | Implementation | Reason |
|---|---|---|
| IRSA | Pod service accounts mapped to IAM roles via OIDC | No long-lived credentials on nodes |
| Network Policies | Deny-all baseline, explicit allow rules per workload | Limits blast radius of a compromised pod |
| Non-root containers | `runAsNonRoot: true`, `runAsUser: 1000` | Defence in depth against container escapes |
| Image scanning | Trivy in Jenkins — blocks pipeline on HIGH/CRITICAL CVEs | Shift-left security, not post-deploy |
| IAM least privilege | No `AdministratorAccess` anywhere in the platform | AWS Well-Architected compliant |
| Secret management | AWS Secrets Manager — no secrets stored in Git | Compliance-ready from day one |

---

## GitOps Layer — Argo CD App of Apps

The App of Apps pattern means a single root application manages all child applications declaratively. Argo CD continuously reconciles the live cluster state with what is committed in Git.

```
app-of-apps.yaml              (root — syncs everything below)
├── namespaces.yaml           → creates dev, prod, argocd, monitoring namespaces
├── infra-apps.yaml           → deploys StorageClass and Ingress Controller
├── helm-apps.yaml            → deploys application via Helm (prod values)
└── kustomize-apps.yaml       → deploys application via Kustomize (dev overlay)
```

**Why both Helm and Kustomize?** This is deliberate. Helm handles third-party charts with complex value trees (ingress-nginx, kube-prometheus-stack). Kustomize handles environment-specific patching of raw manifests without a templating language. Both patterns are standard in real platform teams.

---

## CI/CD Pipeline — Jenkins Shared Library

The Jenkins Shared Library (`eksPipeline.groovy`) is the key pattern here. Instead of duplicating pipeline logic across every repo, any team calls a single reusable function:

```groovy
// Any team's Jenkinsfile — one call gets a full DevSecOps pipeline
eksPipeline(
  appName: 'demo-app',
  ecrRepo: '123456789.dkr.ecr.ap-southeast-2.amazonaws.com/demo-app',
  environment: 'prod'
)
```

The shared library runs these stages automatically:

```
Stage 1 → Checkout
Stage 2 → Build Docker image
Stage 3 → Trivy scan        (blocks on HIGH or CRITICAL CVEs)
Stage 4 → SonarQube gate    (blocks below coverage threshold)
Stage 5 → Terraform validate
Stage 6 → Push to ECR
Stage 7 → Trigger Argo CD sync
```

This is the same pattern I implemented at Universus Infotech to standardise CI/CD across 8+ development teams — one update to the shared library propagates improvements to every pipeline simultaneously.

---

## Kubernetes Operational Standards

Every workload in this platform follows the same production manifest standards:

```yaml
readinessProbe:             # Traffic only routes when the app is ready
  httpGet:
    path: /ready
livenessProbe:              # Pod restarts automatically if the app hangs
  httpGet:
    path: /health
resources:
  requests:
    cpu: "100m"             # Scheduler uses this for node placement
    memory: "128Mi"
  limits:
    cpu: "500m"             # Prevents noisy-neighbour CPU starvation
    memory: "256Mi"
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  readOnlyRootFilesystem: true
```

**HPA** is configured on all deployments — the platform scales workloads automatically on CPU utilisation without manual intervention.

**Kustomize overlays** allow dev to run with 1 replica and relaxed probe timeouts, while prod runs with 3 replicas, stricter probes, and pod anti-affinity rules to spread across availability zones.

---

## Monitoring & Observability

Observability is built into the platform standard — not added as an afterthought.

- All pods carry Prometheus scrape annotations (`prometheus.io/scrape: "true"`)
- Health endpoints (`/health`, `/ready`) required by the deployment standard
- CloudWatch Container Insights enabled at the EKS cluster level
- kube-prometheus-stack integration documented in `/monitoring`
- HPA scaling events and Argo CD sync results feed into alerting

---

## How to Deploy

### Prerequisites

- AWS CLI configured (`aws configure`)
- Terraform >= 1.5
- kubectl
- Argo CD CLI (optional)

### 1 — Provision infrastructure

```bash
cd infrastructure
terraform init
terraform plan  -var="aws_region=ap-southeast-2"
terraform apply -var="aws_region=ap-southeast-2"
```

### 2 — Configure kubectl

```bash
aws eks update-kubeconfig \
  --region ap-southeast-2 \
  --name $(terraform output -raw cluster_name)
```

### 3 — Bootstrap GitOps

```bash
# Install Argo CD
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Apply the root App of Apps — Argo CD handles everything from here
kubectl apply -f argocd/app-of-apps.yaml
```

### 4 — Useful Makefile targets

```bash
make plan          # terraform plan
make apply         # terraform apply
make deploy-dev    # kubectl apply -k kubernetes/overlays/dev
make deploy-prod   # kubectl apply -k kubernetes/overlays/prod
make sync          # trigger Argo CD sync
```

---

## Why I Built It This Way

Every decision in this platform is intentional.

**Terraform modules over a monolithic config** — Real teams reuse infrastructure patterns. Modules enforce a consistent, tested interface and make multi-account provisioning tractable without duplicating code.

**Argo CD over push-based CI deployment** — Pull-based GitOps means the cluster always reconciles to a known Git state. Drift is detected and corrected automatically. Rollback is a `git revert`.

**Jenkins Shared Library** — Copy-paste CI pipelines across teams are a maintenance disaster. One shared library means one place to update the Trivy version, one place to change the quality gate threshold, zero drift between teams.

**Both Kustomize and Helm** — In real environments you use the right tool for the job. Helm for third-party charts with complex value hierarchies. Kustomize for patching your own manifests cleanly across environments.

**Security from day one** — IRSA, Network Policies, and non-root containers are not optional extras. They are part of the deployment standard. Every workload must meet these requirements before it reaches prod.

---

## Author

**Ravikumar Lanka** — DevOps & Cloud Engineer
Canberra, ACT, Australia | Australian Permanent Resident

[![LinkedIn](https://img.shields.io/badge/LinkedIn-ravikumarlanka-0A66C2?logo=linkedin&logoColor=white)](https://linkedin.com/in/ravikumarlanka)
[![GitHub](https://img.shields.io/badge/GitHub-ravilanka999-181717?logo=github&logoColor=white)](https://github.com/ravilanka999)
[![Email](https://img.shields.io/badge/Email-ravikumar.lanka%40outlook.com-0078D4?logo=microsoftoutlook&logoColor=white)](mailto:ravikumar.lanka@outlook.com)
