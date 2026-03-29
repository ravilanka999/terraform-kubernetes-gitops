variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cluster_name" {
  description = "Name for the EKS cluster (if empty, auto-generated)"
  type        = string
  default     = ""
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = "1.33"
}

variable "vpc_id" {
  description = "ID of the VPC to create cluster in"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for worker nodes"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs (for public endpoint access if needed)"
  type        = list(string)
  default     = []
}

variable "enable_public_access" {
  description = "Enable public endpoint access (false recommended for production)"
  type        = bool
  default     = false
}

variable "node_instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "m5.xlarge"
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 10
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "enable_coredns" {
  description = "Enable CoreDNS addon"
  type        = bool
  default     = true
}

variable "enable_kube_proxy" {
  description = "Enable kube-proxy addon"
  type        = bool
  default     = true
}

variable "enable_vpc_cni" {
  description = "Enable VPC CNI addon"
  type        = bool
  default     = true
}

variable "enable_ebs_csi_driver" {
  description = "Enable EBS CSI driver addon"
  type        = bool
  default     = true
}

variable "enable_efs_csi_driver" {
  description = "Enable EFS CSI driver addon"
  type        = bool
  default     = false
}

variable "enable_pod_identity" {
  description = "Enable EKS Pod Identity agent"
  type        = bool
  default     = true
}

variable "control_plane_sg_id" {
  description = "Security group ID for EKS control plane (optional)"
  type        = string
  default     = ""
}

variable "node_sg_id" {
  description = "Security group ID for worker nodes (optional)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}
