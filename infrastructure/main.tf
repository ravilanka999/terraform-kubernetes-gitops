module "vpc" {
  source = "./modules/vpc"

  project_name          = var.project_name
  environment           = var.environment
  vpc_cidr              = var.vpc_cidr
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs
  availability_zones    = var.availability_zones

  tags = var.tags
}

module "security_groups" {
  source = "./modules/security-groups"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  vpc_cidr     = var.vpc_cidr

  tags = var.tags
}

module "eks" {
  source = "./modules/eks"

  project_name       = var.project_name
  environment        = var.environment
  cluster_name       = var.eks_cluster_name
  kubernetes_version = var.kubernetes_version
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  aws_region         = var.aws_region

  node_instance_type = var.eks_node_instance_type
  node_min_size      = var.eks_node_min_size
  node_max_size      = var.eks_node_max_size
  node_desired_size  = var.eks_node_desired_size

  enable_coredns        = var.enable_coredns
  enable_ebs_csi_driver = var.enable_ebs_csi_driver
  enable_vpc_cni        = var.enable_vpc_cni
  enable_pod_identity   = var.enable_pod_identity
  enable_public_access  = true  # Enable for demo/portfolio access

  control_plane_sg_id = module.security_groups.eks_control_plane_sg_id
  node_sg_id          = module.security_groups.eks_node_sg_id

  tags = var.tags
}

# Optional: Enable cluster creator admin permissions
# In production, use IAM Identity Center or OIDC instead
resource "aws_iam_role_policy_attachment" "cluster_creator_admin" {
  count = var.enable_cluster_creator_admin ? 1 : 0

  role       = module.eks.cluster_iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
