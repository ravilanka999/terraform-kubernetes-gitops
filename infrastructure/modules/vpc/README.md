# VPC Module

Creates a production-ready VPC with:
- Public subnets (for load balancers, NAT gateways)
- Private subnets (for application workloads)
- Database subnets (for RDS, ElastiCache, etc.)
- Internet Gateway
- NAT Gateways (HA across AZs)
- Route tables with appropriate routing
- VPC Flow Logs (optional)

## Usage

```hcl
module "vpc" {
  source = "./modules/vpc"

  project_name         = "my-app"
  environment          = "dev"
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  database_subnet_cidrs = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
  availability_zones   = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]

  tags = {
    Owner = "DevOps Team"
  }
}
```

## Outputs

- `vpc_id` - ID of the created VPC
- `public_subnet_ids` - IDs of public subnets
- `private_subnet_ids` - IDs of private subnets
- `database_subnet_ids` - IDs of database subnets
- `internet_gateway_id` - ID of the IGW
- `nat_gateway_ids` - IDs of NAT gateways

## Design Decisions

1. **Three-Tier Subnet Architecture**: Separates public, private, and database workloads for security and routing flexibility.
2. **HA NAT Gateways**: One NAT Gateway per AZ to avoid single point of failure.
3. **Flow Logs Enabled**: Captures VPC traffic for security monitoring.
4. **Tagging Strategy**: Consistent tags across all resources for cost allocation and governance.

## Cost Optimization

For non-production environments, consider:
- Using fewer AZs (e.g., only 2 instead of 3)
- Disabling NAT Gateways if not needed (use public endpoints)
- Disabling VPC Flow Logs if not required
