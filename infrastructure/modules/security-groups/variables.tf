variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC to create security groups in"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC (for internal access rules)"
  type        = string
}

variable "create_bastion_sg" {
  description = "Whether to create bastion host security group"
  type        = bool
  default     = false
}

variable "create_alb_sg" {
  description = "Whether to create ALB ingress security group"
  type        = bool
  default     = false
}

variable "bastion_ssh_cidr" {
  description = "CIDR block allowed to SSH to bastion (default: 0.0.0.0/0 - NOT SECURE FOR PROD)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}
