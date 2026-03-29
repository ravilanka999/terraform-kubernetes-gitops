# Architecture Decision Records (ADRs)

This document captures key architectural decisions for the Terraform Kubernetes GitOps Platform.

---

## ADR-001: Modular Terraform Structure

### **Context**
We needed to provision a production-grade EKS cluster and supporting infrastructure while maintaining code reusability across multiple environments and projects.

### **Decision**
Adopted a modular Terraform architecture with separate modules for VPC, EKS, and Security Groups. Modules are version-controlled independently (in same repo for simplicity) and called from root `main.tf`.

### **Consequences**
- ✅ **Reusability**: Same modules can be used across dev/staging/prod with different inputs
- ✅ **Isolation**: Changes to VPC don't affect EKS configuration
- ✅ **Testing**: Modules can be tested independently
- ⚠️ **Complexity**: More directories and files to manage
- ⚠️ **State Management**: Multiple modules increase state file size (mitigated by S3 backend)

---

## ADR-002: App of Apps Pattern for GitOps

### **Context**
We need a scalable way to manage deployments of multiple applications (namespaces, infrastructure, demo app) across multiple environments (dev, prod) without manual intervention.

### **Decision**
Use Argo CD's **App of Apps** pattern:
- Root application (`app-of-apps.yaml`) manages all other applications
- Applications directory contains Argo CD Application manifests for each logical group
- Each application can have its own sync policy and destination

### **Consequences**
- ✅ **Hierarchical Management**: Changes to root app propagate to children
- ✅ **Independent Sync**: Each app can sync on its own schedule
- ✅ **Environments as Apps**: Dev and prod are separate Applications
- ⚠️ **Initial Setup Complexity**: Requires understanding of Argo CD Application CRDs
- ⚠️ **Dependency Management**: Need to coordinate sync order (use `syncOptions` or waves)

---

## ADR-003: Kustomize over Helm for Application Manifests

### **Context**
Our demo application needs environment-specific variations (replica count, HPA thresholds, probes). We needed a solution to manage these without duplicating YAML.

### **Decision**
Use **Kustomize** (native to `kubectl`) for environment overlays:
- `kubernetes/base/` contains common manifests
- `kubernetes/overlays/dev/` and `overlays/prod/` contain environment patches
- Overlays reference base via `resources:` and apply patches via `patchesStrategicMerge`

### **Consequences**
- ✅ **No Templating Language**: Pure YAML, easier to read and debug
- ✅ **GitOps Friendly**: Same code can be applied to multiple clusters
- ✅ **Environment Isolation**: Clear separation between dev and prod configs
- ⚠️ **Limited Logic**: Kustomize doesn't support if/else logic (use Helm for complex templating)
- ⚠️ **Immutability**: Can't dynamically generate resources based on conditions

---

## ADR-004: Helm for Packaged Applications

### **Context**
Some third-party applications (ingress controllers, monitoring stacks) are best installed via Helm charts due to complexity and community support.

### **Decision**
Include Helm charts in `helm-charts/` directory and deploy via Argo CD's Helm support (or helm-apps.yaml Application). Created `demo-app` chart as a template.

### **Consequences**
- ✅ **Standard Ecosystem**: Access to hundreds of community Helm charts
- ✅ **Parameterization**: Helm values files for environments
- ✅ **Dependencies**: Helm can manage chart dependencies (e.g., postgresql as dependency)
- ⚠️ **Templating Complexity**: Go templates add another layer to learn
- ⚠️ **Debugging**: Rendered manifests are generated, harder to inspect

---

## ADR-005: Separate Terraform State per Environment

### **Context**
We need to manage EKS clusters for dev, staging, and prod without risking production from dev operations.

### **Decision**
Use separate Terraform workspaces OR separate state files via `-var-file` approach. In this repo, we use **directories** (could have `environments/dev/`, `environments/prod/` pointing to same modules). For simplicity, we used single `infrastructure/` with `terraform.tfvars` file.

**Recommended production approach**: Separate state files per environment with backend config variable interpolation.

### **Consequences**
- ✅ **Isolation**: Dev and prod state files are separate
- ⚠️ **Duplication**: Need to maintain separate variable files
- ✅ **Safety**: Cannot accidentally destroy prod from dev environment

---

## ADR-006: Private EKS Endpoint with Bastion Access

### **Context**
Security best practice is to disable public access to EKS API server. However, we still need admin access for troubleshooting.

### **Decision**
- Set `endpoint_public_access = false` in EKS module
- Deploy a bastion host in public subnet
- Use AWS SSM Session Manager to connect to bastion (no SSH keys needed)
- Configure `kubectl` via `aws eks update-kubeconfig` which uses IAM authentication through the endpoint

### **Consequences**
- ✅ **Enhanced Security**: Kubernetes API not exposed to internet
- ✅ **No SSH Keys**: Use IAM for authentication
- ⚠️ **Additional Component**: Bastion must be maintained
- ⚠️ **Latency**: Extra hop for terminal access

---

## ADR-007: EBS StorageClass with WaitForFirstConsumer

### **Context**
We need persistent storage for stateful applications but want to optimize costs and availability.

### **Decision**
- Create `ebs-sc` StorageClass with `volumeBindingMode: WaitForFirstConsumer`
- Storage volume is not created until a pod requests it
- Volume is created in the same AZ as the pod (improves performance)
- ReclaimPolicy: `Retain` for data safety (manual cleanup requires explicit deletion)
- Use `gp3` volume type (general purpose SSD) for cost-performance balance

### **Consequences**
- ✅ **Cost Optimization**: Avoids pre-provisioning unused storage
- ✅ **HA**: Pods scheduled in specific AZs, volumes created there
- ⚠️ **Manual Cleanup**: Retain policy means PVC deletion doesn't auto-delete PV (intentional)

---

## ADR-008: Non-Root Containers with Security Context

### **Context**
Kubernetes runs containers as root by default (UID 0). This violates security best practices and can be a container escape vector.

### **Decision**
- Set `runAsNonRoot: true` in pod securityContext
- Set `runAsUser: 1000` and `runAsGroup: 1000` (non-privileged user)
- Set `fsGroup: 2000` for volume permissions
- `seccompProfile: RuntimeDefault` to drop unnecessary syscalls

### **Consequences**
- ✅ **Security Hardening**: Mitigates container breakout attacks
- ✅ **Compliance**: Meets CIS benchmarks and security standards
- ⚠️ **Application Requirements**: Application must be able to run as non-root (most can)

---

## ADR-009: HPA for Autoscaling

### **Context**
Static replica counts lead to either resource waste (over-provisioned) or poor performance (under-provisioned). We need automatic scaling.

### **Decision**
- Use Horizontal Pod Autoscaler (HPA) for all stateless services
- Scale on CPU and memory metrics (can extend to custom metrics)
- Configured conservatively in dev (faster scaling), cautiously in prod (avoid thrashing)
- Use scaling behavior policies to control ramping speed

### **Consequences**
- ✅ **Cost Efficiency**: Scale down when load is low (dev)
- ✅ **Performance**: Scale up during traffic spikes
- ⚠️ **Metric Dependencies**: Requires metrics-server installed
- ⚠️ **Cold Starts**: Pods take time to start (mitigate with readiness probes and min replicas)

---

## ADR-010: Network Policies for Zero-Trust Network

### **Context**
By default, all pods can communicate with each other (flat network). This violates principle of least privilege and allows lateral movement if a pod is compromised.

### **Decision**
- Deploy NetworkPolicy resources to restrict pod-to-pod communication
- Explicitly allow only necessary ingress/egress
- Default deny all other traffic
- Policies differ by environment (dev may be permissive, prod strict)

### **Consequences**
- ✅ **Security**: Limits blast radius of compromised pods
- ✅ **Compliance**: Required for many certifications (PCI, HIPAA)
- ⚠️ **Complexity**: Requires understanding of all service dependencies
- ⚠️ **CNI Plugin Required**: Calico, Cilium, or Weave (default kube-router doesn't enforce)

---

## ADR-011: Argo CD Automated Sync with Self-Healing

### **Context**
Manual deployments (`kubectl apply`) are error-prone and don't scale. We want Git to be the single source of truth.

### **Decision**
- Enable `automated` sync in Argo CD Application specs
- Set `prune: true` to delete resources removed from Git
- Set `selfHeal: true` to revert manual changes in cluster
- Use `CreateNamespace=true` for convenience

### **Consequences**
- ✅ **GitOps**: All cluster state originates from Git
- ✅ **Self-Healing**: Accidental manual changes are automatically corrected
- ✅ **Auditability**: Git history shows who changed what
- ⚠️ **Dangerous**: Prune can delete resources unexpectedly (test before production)
- ⚠️ **Drift Detection**: Always know if cluster matches Git

---

## ADR-012: Labels for Organization and Discovery

### **Context**
Resources across multiple namespaces need to be identifiable by application, environment, and component for management, monitoring, and RBAC.

### **Decision**
Apply standardized labels to **all** resources:

```yaml
labels:
  app.kubernetes.io/name: demo-app        # Helm-style naming
  app.kubernetes.io/instance: demo-app    # Release/instance
  component: app/database/service         # Microservice component
  project: gitops-demo                    # Project name
  tier: application/infrastructure        # Layer
  environment: dev/prod                   # Environment
```

### **Consequences**
- ✅ **Discoverability**: `kubectl get all -l project=gitops-demo`
- ✅ **RBAC**: Role-based access control can target labels
- ✅ **Cost Tracking**: Labels can be used for AWS cost allocation
- ✅ **Monitoring**: Prometheus can use labels for metric grouping
- ⚠️ **Consistency Requirement**: All manifests must follow label conventions

---

## ADR-013: Terraform Remote State with S3 + DynamoDB

### **Context**
Local Terraform state files (`terraform.tfstate`) don't support team collaboration, can be lost, and allow concurrent modifications causing corruption.

### **Decision**
- Use S3 backend for remote state storage
- Enable encryption at rest
- Use DynamoDB table for state locking (prevents concurrent runs)
- State file key organized by environment: `infrastructure/terraform.tfstate`

### **Consequences**
- ✅ **Team Collaboration**: Multiple engineers can run Terraform safely
- ✅ **Durability**: S3 provides 99.999999999% durability
- ✅ **Concurrency Safety**: DynamoDB locks prevent corruption
- ⚠️ **AWS Dependencies**: Requires S3 bucket and DynamoDB table pre-created
- ⚠️ **Cost**: Small charges for S3 storage and DynamoDB reads/writes
- ⚠️ **Security**: S3 bucket must be locked down with IAM policies

---

## Future Considerations

- **Service Mesh**: Consider Istio or Linkerd for advanced traffic management
- **Secrets Management**: Integrate with AWS Secrets Manager or HashiCorp Vault via External Secrets Operator
- **Observability**: Deploy Prometheus stack (kube-prometheus-stack Helm chart)
- **Backup/Restore**: Velero for cluster resource backups
- **Multi-Cluster**: Extend to multi-region with Cluster API or Terraform workspaces
- **GitOps CI/CD**: Add automated PR preview environments via Argo CD

---

**Last Updated:** 2025-03-29
**Maintainer:** DevOps Team
