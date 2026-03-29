# Security Groups Module

Creates security groups for EKS cluster and supporting infrastructure.

## Security Groups Created

1. **EKS Control Plane SG**: Allows access to EKS API server (typically from EKS nodes and bastion)
2. **EKS Node SG**: Controls ingress/egress for worker nodes
3. **Bastion SG** (optional): For SSH access to jump host
4. **ALB Ingress SG** (optional): For Application Load Balancer

## Usage

```hcl
module "security_groups" {
  source = "./modules/security-groups"

  project_name = "my-app"
  environment  = "dev"
  vpc_id       = module.vpc.vpc_id
  vpc_cidr     = module.vpc.vpc_cidr

  create_bastion_sg  = true
  create_alb_sg      = true
  bastion_ssh_cidr   = "203.0.113.0/24"  # Restrict to your IP!

  tags = var.tags
}
```

## Security Notes

⚠️ **CRITICAL**: The default `bastion_ssh_cidr = "0.0.0.0/0"` allows SSH from anywhere. **Always override in production** with a specific CIDR.

Example for production:
```hcl
bastion_ssh_cidr = "10.0.0.0/16"  # Only allow from within VPC
# or
bastion_ssh_cidr = "203.0.113.0/24"  # Your corporate IP range
```

## EKS Node Security Group Rules

The EKS node security group:
- Allows all outbound traffic (required for pulling images, etc.)
- Allows intra-node communication (self rule)
- EKS automatically adds rules for cluster communication (you can add additional rules as needed)

For production, consider adding rules to restrict:
- Pod-to-pod communication (use Network Policies instead)
- Access to databases (use database SGs)
- External API access (egress rules)

## Integration with EKS Module

The EKS module will automatically use these security groups:
- `eks_control_plane_sg_id` for cluster endpoint access
- `eks_node_sg_id` for worker nodes

No additional configuration needed.

## Outputs

- `eks_control_plane_sg_id` - SG for EKS API endpoint
- `eks_node_sg_id` - SG for worker nodes
- `bastion_sg_id` - SG for bastion (if created)
- `alb_ingress_sg_id` - SG for ALB (if created)
