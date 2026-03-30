output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "database_subnet_ids" {
  description = "IDs of the database subnets"
  value       = module.vpc.database_subnet_ids
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint of the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_version" {
  description = "Version of the EKS cluster"
  value       = module.eks.cluster_version
}

output "eks_node_group_ids" {
  description = "IDs of the EKS managed node groups"
  value       = module.eks.node_group_ids
}

output "eks_cluster_iam_role_arn" {
  description = "ARN of the IAM role used by the EKS cluster"
  value       = module.eks.cluster_iam_role_arn
}

output "eks_node_iam_role_arn" {
  description = "ARN of the IAM role used by EKS nodes"
  value       = module.eks.node_iam_role_arn
}

output "kubeconfig" {
  description = "Kubeconfig for the EKS cluster (sensitive)"
  value       = <<EOT
# Run this command to update your kubeconfig:
aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}
EOT
  sensitive   = false
}

# Optional outputs for future modules (bastion, alb) can be added when those modules are implemented
# output "bastion_public_ip" {
#   description = "Public IP of the bastion host"
#   value       = var.environment == "dev" ? module.bastion.public_ip : null
# }
#
# output "load_balancer_ingress_hostname" {
#   description = "Hostname of the ALB ingress controller"
#   value       = var.environment == "prod" ? module.alb.ingress_hostname : null
# }
