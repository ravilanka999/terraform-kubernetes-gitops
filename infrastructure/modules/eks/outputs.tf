output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.main.id
}

output "cluster_arn" {
  description = "Amazon Resource Name (ARN) of the cluster"
  value       = aws_eks_cluster.main.arn
}

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint of the EKS cluster"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_version" {
  description = "Kubernetes version of the cluster"
  value       = aws_eks_cluster.main.version
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded certificate data for the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for IAM Roles for Service Accounts (IRSA)"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "node_group_ids" {
  description = "IDs of the EKS managed node groups"
  value       = { "default" = aws_eks_node_group.main.id }
}

output "node_group_arns" {
  description = "ARNs of the EKS managed node groups"
  value       = { "default" = aws_eks_node_group.main.arn }
}

output "node_iam_role_arn" {
  description = "ARN of the IAM role used by EKS nodes"
  value       = aws_iam_role.nodes.arn
}

output "node_iam_role_name" {
  description = "Name of the IAM role used by EKS nodes"
  value       = aws_iam_role.nodes.name
}

output "cluster_iam_role_arn" {
  description = "ARN of the IAM role used by the EKS cluster"
  value       = aws_iam_role.cluster.arn
}

output "cluster_iam_role_name" {
  description = "Name of the IAM role used by the EKS cluster"
  value       = aws_iam_role.cluster.name
}

output "cluster_security_group_id" {
  description = "Security group ID of the cluster (EKS managed)"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "node_security_group_id" {
  description = "Security group ID of the nodes (if configured)"
  value       = try(aws_eks_node_group.main.resources[0].remote_access_security_group_id, null)
}

output "addon_versions" {
  description = "Versions of installed EKS addons"
  value = {
    coredns      = var.enable_coredns ? aws_eks_addon.coredns[0].addon_version : null
    vpc_cni      = var.enable_vpc_cni ? aws_eks_addon.vpc_cni[0].addon_version : null
    ebs_csi      = var.enable_ebs_csi_driver ? aws_eks_addon.ebs_csi[0].addon_version : null
    pod_identity = var.enable_pod_identity ? aws_eks_addon.pod_identity[0].addon_version : null
  }
}

output "oidc_issuer" {
  description = "OIDC issuer URL (for IRSA)"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "platform_version" {
  description = "EKS platform version"
  value       = aws_eks_cluster.main.platform_version
}
