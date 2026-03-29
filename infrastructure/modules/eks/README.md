# EKS Module

Creates an Amazon EKS cluster with managed node groups using IAM roles (recommended approach).

## Features

- ✅ EKS cluster with version selection (1.33 by default)
- ✅ Managed node groups with auto-scaling
- ✅ IAM roles for nodes (following AWS best practices)
- ✅ EKS addons (CoreDNS, VPC CNI, EBS CSI, Pod Identity)
- ✅ CloudWatch logging for all cluster components
- ✅ Private endpoint access (secure by default)
- ✅ Optional public endpoint access
- ✅ OIDC provider for IAM Roles for Service Accounts (IRSA)

## Usage

```hcl
module "eks" {
  source = "./modules/eks"

  project_name           = "my-app"
  environment            = "dev"
  cluster_name           = "my-eks-cluster"
  kubernetes_version     = "1.33"

  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnet_ids

  node_instance_type     = "m5.large"
  node_min_size          = 2
  node_max_size          = 10
  node_desired_size      = 2

  enable_coredns         = true
  enable_ebs_csi_driver  = true
  enable_vpc_cni        = true
  enable_pod_identity    = true

  control_plane_sg_id    = module.security_groups.eks_control_plane_sg_id
  node_sg_id             = module.security_groups.eks_node_sg_id

  tags = {
    Owner = "DevOps Team"
  }
}
```

## Security Considerations

1. **Private Endpoint**: By default, `enable_public_access = false`. This means the Kubernetes API is only accessible from within the VPC (via bastion or VPC peering). **This is the secure configuration for production.**

2. **IAM Roles for Service Accounts (IRSA)**: The cluster OIDC provider is automatically created. Use this to grant AWS permissions to pods without using long-term credentials.

3. **Node Security Groups**: Pass in custom security groups from the `security-groups` module to control node-level network access.

4. **Cluster Creator Admin**: Don't use the `enable_cluster_creator_admin` flag in production. Instead:
   - Use IAM Identity Center (successor to AWS SSO)
   - Use OIDC groups mapped to RBAC
   - Or create specific IAM users/roles with minimal permissions

## Addons

EKS addons are managed by AWS and provide:
- **CoreDNS**: DNS resolution for services
- **VPC CNI**: Pod networking (required)
- **EBS CSI**: Persistent storage with EBS volumes
- **Pod Identity**: IAM integration for pods (IRSA)
- **kube-proxy**: Enables Kubernetes service networking
- **aws-node**: VPC CNI daemonset

You can enable/disable each based on your needs. In production, enable all relevant addons.

## Node Groups

This module creates a single managed node group. For multi-instance-type/node-role scenarios, you can:
1. Create multiple node groups (use `for_each` in root)
2. Use instance selector (mix of instance types)
3. Use different AMI types (AL2023, Amazon Linux 2)

Example with multiple node groups:
```hcl
module "eks" {
  source = "./modules/eks"

  # ... base config

  node_groups = {
    general = {
      instance_types = ["m5.xlarge", "m5.2xlarge"]
      min_size       = 2
      max_size       = 10
      desired_size   = 2
    }
    spot = {
      instance_types = ["m5.xlarge", "m5.2xlarge"]
      min_size       = 0
      max_size       = 5
      desired_size   = 0
      capacity_type  = "SPOT"
    }
  }
}
```

## Outputs

- `cluster_name` - Name of the EKS cluster
- `cluster_endpoint` - API server endpoint
- `cluster_version` - Kubernetes version
- `oidc_issuer` - OIDC issuer URL for IRSA
- `node_iam_role_arn` - IAM role ARN for worker nodes
- `cluster_iam_role_arn` - IAM role ARN for cluster
- `cluster_certificate_authority_data` - Certificate for kubectl

## Cost Optimization

- Use **spot instances** for non-critical workloads:
  ```hcl
  capacity_type = "SPOT"
  ```

- **Right-size** node instances (monitor with CloudWatch)

- Use **cluster autoscaling** with multiple instance types:
  ```hcl
  instance_types = ["m5.xlarge", "m6i.xlarge", "c5.xlarge"]
  ```

- **Scale down** node groups to 0 when not in use (dev environments):
  ```hcl
  node_desired_size = 0
  node_min_size     = 0
  ```

## References

- [AWS EKS Terraform Module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [IRSA Guide](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
