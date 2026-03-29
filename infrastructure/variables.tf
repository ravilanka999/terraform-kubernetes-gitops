variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-2"
}

variable "aws_profile" {
  description = "AWS CLI profile name (optional)"
  type        = string
  default     = ""
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "gitops-demo"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Owner       = "DevOps Engineer"
    Project     = "GitOps Platform"
    Environment = "Development"
    ManagedBy   = "Terraform"
  }
}

# VPC Variables
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

variable "database_subnet_cidrs" {
  description = "CIDR blocks for database subnets"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
}

variable "availability_zones" {
  description = "Availability zones to use"
  type        = list(string)
  default     = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
}

# EKS Variables
variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "gitops-eks"
}

variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.33"
}

variable "eks_node_instance_type" {
  description = "Instance type for EKS managed node group"
  type        = string
  default     = "m5.xlarge"
}

variable "eks_node_min_size" {
  description = "Minimum number of nodes in the node group"
  type        = number
  default     = 2
}

variable "eks_node_max_size" {
  description = "Maximum number of nodes in the node group"
  type        = number
  default     = 10
}

variable "eks_node_desired_size" {
  description = "Desired number of nodes in the node group"
  type        = number
  default     = 2
}

variable "enable_coredns" {
  description = "Enable CoreDNS addon"
  type        = bool
  default     = true
}

variable "enable_ebs_csi_driver" {
  description = "Enable EBS CSI driver addon"
  type        = bool
  default     = true
}

variable "enable_vpc_cni" {
  description = "Enable VPC CNI addon"
  type        = bool
  default     = true
}

variable "enable_pod_identity" {
  description = "Enable EKS Pod Identity agent"
  type        = bool
  default     = true
}

variable "create_additional_sgs" {
  description = "Create additional security groups (if false, use module defaults)"
  type        = bool
  default     = false
}

variable "enable_cluster_creator_admin" {
  description = "Give cluster creator admin permissions (for demo/learning only)"
  type        = bool
  default     = true
}
