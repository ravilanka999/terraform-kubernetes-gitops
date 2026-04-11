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

This repository showcases how I design and operate cloud-native infrastructure. The focus is entirely on the **platform layer** — how infrastructure is provisioned, how workloads are deployed reliably, how pipelines enforce quality and security, and how systems stay observable and resilient under real production conditions.

> **Note:** The application workload (a Flask REST API) exists solely as a deployable artefact to exercise the platform. The value is everything around it — the IaC, the GitOps engine, the pipeline, and the operational standards applied to every workload.

| Capability | Implementation |
|---|---|
| Infrastructure as Code | Modular Terraform (VPC, EKS, Security Groups) with S3 remote state |
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
│   ├── variables.tf / outputs.tf / providers.tf
│   ├── backend.tf                    # S3 remote state + DynamoDB lock
│   ├── terraform.tfvars.example      # Example values to get started
│   └── modules/
│       ├── vpc/                      # Multi-AZ VPC, public/private subnets, NAT
│       ├── eks/                      # EKS managed node groups, OIDC, IRSA
│       └── security-groups/          # Least-privilege security group rules
│
├── kubernetes/                       # Kubernetes manifests
│   ├── base/                         # Reusable base templates
│   │   ├── deployment.yaml           # Non-root, resource-limited, health-probed
│   │   ├── hpa.yaml                  # Horizontal Pod Autoscaler
│   │   ├── networkpolicy.yaml        # Pod-to-pod traffic control
│   │   └── kustomization.yaml
│   └── overlays/
│       ├── dev/                      # Dev: 1 replica, relaxed probes
│       └── prod/                     # Prod: 3 replicas, strict probes, anti-affinity
│
├── helm-charts/demo-app/             # Helm packaging with per-environment values
│   ├── values.yaml / values-dev.yaml / values-prod.yaml
│   └── templates/                    # Deployment, Service, HPA, NetworkPolicy, ConfigMap
│
├── argocd/                           # GitOps definitions
│   ├── app-of-apps.yaml              # Root application — manages everything below
│   └── applications/
│       ├── namespaces.yaml           # Environment namespace declarations
│       ├── infra-apps.yaml           # StorageClass, Ingress Controller
│       ├── helm-apps.yaml            # Application via Helm (prod)
│       └── kustomize-apps.yaml       # Application via Kustomize (dev)
│
├── jenkins/                          # CI/CD pipeline
│   ├── Jenkinsfile                   # Multi-stage pipeline definition
│   └── shared-library/vars/
│       └── eksPipeline.groovy        # Reusable shared library
│
├── namespaces/                       # dev / prod / argocd / monitoring
├── monitoring/                       # kube-prometheus-stack integration guide
├── docs/
│   ├── architecture-decisions.md     # ADRs explaining every key decision
│   ├── security-considerations.md    # Security model and controls
│   └── deployment-guide.md           # Step-by-step deployment walkthrough
├── .github/workflows/terraform.yml   # GitHub Actions — Terraform validate/plan on PR
└── Makefile                          # Common operational targets
```

---

## Infrastructure Deep Dive

### Terraform Modules

Each module is self-contained with its own `variables.tf`, `outputs.tf`, and `README.md`.

**VPC module** provisions a multi-AZ network: public subnets for load balancers, private subnets for worker nodes, NAT Gateways per AZ, and route tables with proper EKS subnet tagging for ALB/NLB auto-discovery.

**EKS module** provisions managed node groups on AL2023 AMI, configures OIDC provider for IRSA, enables the EBS CSI driver for dynamic persistent storage, and installs the AWS Load Balancer Controller. The cluster API endpoint is private — access goes through bastion host only, not the public internet.

**Remote state** uses S3 with versioning enabled and DynamoDB for state locking, preventing concurrent `terraform apply` conflicts across team members or pipeline runs.

### Security Design

| Control | Implementation | Why |
|---|---|---|
| IRSA | Pod service accounts mapped to IAM roles via OIDC | No static credentials on nodes or in environment variables |
| Network Policies | Deny-all baseline + explicit allow rules per workload | Limits blast radius if a pod is compromised |
| Non-root containers | `runAsNonRoot: true`, `runAsUser: 1000` | Defence-in-depth against container escape |
| Image scanning | Trivy in Jenkins pipeline — blocks on HIGH/CRITICAL | Shift-left: vulnerabilities caught before deployment |
| IAM least privilege | No `AdministratorAccess` — scoped roles per service | AWS Well-Architected Security Pillar compliant |
| Secret management | AWS Secrets Manager via IRSA pod-level injection | Zero secrets in Git, zero secrets in environment variables |

---

## GitOps Layer — Argo CD App of Apps

A single root application manages all child applications declaratively. Argo CD continuously reconciles the live cluster state against Git — drift is automatically corrected.

```
app-of-apps.yaml                    ← root, apply this once
├── namespaces.yaml                 → creates dev, prod, argocd, monitoring
├── infra-apps.yaml                 → StorageClass + Ingress Controller
├── helm-apps.yaml                  → application via Helm (prod values)
└── kustomize-apps.yaml             → application via Kustomize (dev overlay)
```

**Why both Helm and Kustomize?** Helm handles third-party charts where a rich ecosystem exists (ingress-nginx, kube-prometheus-stack). Kustomize handles environment-specific patching of internal manifests without a templating language. Using both is standard in real platform teams — this repo demonstrates both patterns intentionally.

---

## CI/CD Pipeline — Jenkins Shared Library

Instead of duplicating pipeline logic across every repository, teams call a single shared function. This is the same pattern used to standardise CI/CD across 8+ development teams in production.

```groovy
// Any team's Jenkinsfile — one call gets a full DevSecOps pipeline
eksPipeline(
  appName: 'demo-app',
  ecrRepo: '123456789.dkr.ecr.ap-southeast-2.amazonaws.com/demo-app',
  environment: 'prod'
)
```

Stages run automatically:

```
1. Checkout
2. Build Docker image
3. Trivy scan          → blocks pipeline on HIGH or CRITICAL CVEs
4. SonarQube gate      → blocks below code quality threshold
5. Terraform validate  → catches IaC issues before apply
6. Push to ECR
7. Trigger Argo CD sync
```

One update to the shared library propagates security and quality improvements to every team's pipeline simultaneously — no copy-paste drift.

---

## Kubernetes Operational Standards

Every workload in this platform meets the same baseline before it can reach production:

```yaml
readinessProbe:              # No traffic until app is confirmed ready
  httpGet: { path: /ready }
livenessProbe:               # Auto-restart if app becomes unresponsive
  httpGet: { path: /health }
resources:
  requests:                  # Drives accurate scheduler placement
    cpu: "100m"
    memory: "128Mi"
  limits:                    # Prevents noisy-neighbour resource starvation
    cpu: "500m"
    memory: "256Mi"
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  readOnlyRootFilesystem: true
```

Dev overlay runs 1 replica with relaxed probe timeouts. Prod overlay runs 3 replicas with strict probes and pod anti-affinity rules spreading pods across availability zones.

---

## Monitoring & Observability

Observability is part of the platform standard — not bolted on later.

- All pods carry `prometheus.io/scrape: "true"` annotations
- `/health` and `/ready` endpoints required by the deployment standard
- CloudWatch Container Insights enabled at the cluster level
- kube-prometheus-stack integration documented in `/monitoring`
- HPA scaling events and Argo CD sync results feed into alerting

---

## How to Deploy

### Prerequisites

- AWS CLI with credentials configured (`aws configure`)
- Terraform >= 1.5
- kubectl
- Argo CD CLI (optional — UI also works)

### 1 — Provision infrastructure

```bash
cd infrastructure
cp terraform.tfvars.example terraform.tfvars   # fill in your values
terraform init
terraform plan  -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

### 2 — Configure kubectl

```bash
aws eks update-kubeconfig \
  --region ap-southeast-2 \
  --name $(terraform output -raw cluster_name)
```

### 3 — Bootstrap GitOps

```bash
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Apply once — Argo CD manages everything from here
kubectl apply -f argocd/app-of-apps.yaml
```

### 4 — Common Makefile targets

```bash
make plan          # terraform plan
make apply         # terraform apply
make deploy-dev    # kubectl apply -k kubernetes/overlays/dev
make deploy-prod   # kubectl apply -k kubernetes/overlays/prod
make sync          # trigger Argo CD sync
```

---

## Design Rationale

Every decision in this platform is deliberate.

**Modular Terraform over a monolithic config** — Modules enforce a consistent, tested interface. Multi-account provisioning becomes tractable. Teams reuse without copying.

**Pull-based GitOps over push-based CI deployment** — The cluster always reconciles to a known Git state. Rollback is `git revert`. Drift is detected and corrected automatically.

**Jenkins Shared Library over per-repo pipelines** — Copy-paste pipelines across teams create maintenance debt and drift. One library, one place to raise the security bar for everyone.

**Both Kustomize and Helm** — Helm for third-party charts with complex value hierarchies. Kustomize for patching internal manifests cleanly across environments. The right tool for each job.

**Security from day one, not day ninety** — IRSA, Network Policies, non-root containers, and image scanning are not optional extras. They are requirements. Every workload meets them before reaching production.

---

## Troubleshooting

```bash
# Argo CD sync issues
kubectl describe app <app-name> -n argocd

# Terraform state
terraform state list
terraform state rm <resource>

# Pod not starting
kubectl describe pod <pod-name> -n <namespace>
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

---

## Author

**Ravikumar Lanka** — DevOps & Cloud Engineer
Canberra, ACT, Australia | Australian Permanent Resident

[![LinkedIn](https://img.shields.io/badge/LinkedIn-ravikumarlanka-0A66C2?logo=linkedin&logoColor=white)](https://linkedin.com/in/ravikumarlanka)
[![GitHub](https://img.shields.io/badge/GitHub-ravilanka999-181717?logo=github&logoColor=white)](https://github.com/ravilanka999)
[![Email](https://img.shields.io/badge/Email-ravikumar.lanka%40outlook.com-0078D4?logo=microsoftoutlook&logoColor=white)](mailto:ravikumar.lanka@outlook.com)

---

*MIT License — see LICENSE for details.*
