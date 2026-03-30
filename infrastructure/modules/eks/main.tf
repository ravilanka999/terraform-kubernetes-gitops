terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# Generate a random suffix for resource names to avoid collisions
resource "random_id" "suffix" {
  byte_length = 2
}

# EKS Cluster IAM Role
resource "aws_iam_role" "cluster" {
  name = "${var.project_name}-${var.environment}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-eks-cluster-role"
    }
  )
}

# Attach AmazonEKSClusterPolicy to cluster role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Attach AmazonEKSVPCResourceController to cluster role
resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

# EKS Node IAM Role
resource "aws_iam_role" "nodes" {
  name = "${var.project_name}-${var.environment}-eks-nodes-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-eks-nodes-role"
    }
  )
}

# Attach AmazonEKSWorkerNodePolicy to node role
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# Attach AmazonEKS_CNI_Policy for VPC CNI
resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# Attach AmazonEC2ContainerRegistryReadOnly for pulling images
resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Attach additional policies for specific addons if needed
resource "aws_iam_role_policy_attachment" "ebs_csi" {
  count = var.enable_ebs_csi_driver ? 1 : 0

  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_iam_role_policy_attachment" "efs_csi" {
  count = var.enable_efs_csi_driver ? 1 : 0

  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
}

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name != "" ? var.cluster_name : "${var.project_name}-${var.environment}-${random_id.suffix.hex}"
  role_arn = aws_iam_role.cluster.arn

  # Kubernetes version
  version = var.kubernetes_version

  # VPC configuration
  vpc_config {
    subnet_ids            = var.private_subnet_ids
    endpoint_private_access = true # Always enable for security
    endpoint_public_access  = var.enable_public_access

    # Optional: Add public subnet IDs for public endpoint access
    # Typically not needed if using private endpoint + bastion
  }

  # Enable EKS features
  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-eks-cluster"
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller,
  ]
}

# EKS Managed Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-${var.environment}-node-group"
  node_role_arn   = aws_iam_role.nodes.arn
  subnet_ids      = var.private_subnet_ids

  instance_types = [var.node_instance_type]

  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  update_config {
    max_unavailable = 1
  }

  labels = merge(
    var.tags,
    {
      role = "worker"
      env  = var.environment
    }
  )

  # Taint configuration (optional - for dedicated nodes)
  # taint {
  #   key    = "dedicated"
  #   value  = "general"
  #   effect = "NO_SCHEDULE"
  # }

  # Launch template for custom configuration (if needed)
  # launch_template {
  #   id      = aws_launch_template.example.id
  #   version = "$Latest"
  # }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-node-group"
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ecr_readonly,
    aws_iam_role_policy_attachment.ebs_csi[0],
  ]
}

# Optional: EKS Addons
resource "aws_eks_addon" "coredns" {
  count = var.enable_coredns ? 1 : 0

  cluster_name      = aws_eks_cluster.main.name
  addon_name        = "coredns"
  addon_version     = "v1.11.1-eksbuild.2" # Check for latest version
  resolve_conflicts_on_create = "OVERWRITE"
  preserve          = false

  depends_on = [aws_eks_cluster.main]
}

resource "aws_eks_addon" "vpc_cni" {
  count = var.enable_vpc_cni ? 1 : 0

  cluster_name      = aws_eks_cluster.main.name
  addon_name        = "vpc-cni"
  addon_version     = "v1.19.1-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
  preserve          = false

  depends_on = [aws_eks_cluster.main]
}

resource "aws_eks_addon" "ebs_csi" {
  count = var.enable_ebs_csi_driver ? 1 : 0

  cluster_name      = aws_eks_cluster.main.name
  addon_name        = "aws-ebs-csi-driver"
  addon_version     = "v1.27.0-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
  preserve          = false

  depends_on = [aws_eks_cluster.main]
}

resource "aws_eks_addon" "pod_identity" {
  count = var.enable_pod_identity ? 1 : 0

  cluster_name      = aws_eks_cluster.main.name
  addon_name        = "eks-pod-identity-agent"
  addon_version     = "v1.3.0-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
  preserve          = false

  depends_on = [aws_eks_cluster.main]
}

# Generate kubeconfig output (informational)
output "kubeconfig_command" {
  description = "Command to generate kubeconfig"
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.main.name} --region ${var.aws_region}"
  sensitive   = false
}
