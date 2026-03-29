output "eks_control_plane_sg_id" {
  description = "Security group ID for EKS control plane"
  value       = aws_security_group.eks_control_plane.id
}

output "eks_node_sg_id" {
  description = "Security group ID for EKS worker nodes"
  value       = aws_security_group.eks_nodes.id
}

output "bastion_sg_id" {
  description = "Security group ID for bastion host (if created)"
  value       = var.create_bastion_sg ? aws_security_group.bastion[0].id : null
}

output "alb_ingress_sg_id" {
  description = "Security group ID for ALB ingress controller (if created)"
  value       = var.create_alb_sg ? aws_security_group.alb_ingress[0].id : null
}
