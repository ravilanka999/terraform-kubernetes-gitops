resource "aws_security_group" "eks_control_plane" {
  name        = "${var.project_name}-${var.environment}-eks-control-plane-sg"
  description = "Security group for EKS control plane (endpoint access)"
  vpc_id      = var.vpc_id

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-eks-control-plane-sg"
    }
  )
}

resource "aws_security_group" "eks_nodes" {
  name        = "${var.project_name}-${var.environment}-eks-nodes-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow communication between nodes in the same SG
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # Allow node-to-node communication on all ports
  # (EKS managed node group will add rules for cluster communication)

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-eks-nodes-sg"
    }
  )
}

# Optional: Bastion host security group (for dev environments)
resource "aws_security_group" "bastion" {
  count = var.create_bastion_sg ? 1 : 0

  name        = "${var.project_name}-${var.environment}-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = var.vpc_id

  # SSH from internet (restrict this in production!)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.bastion_ssh_cidr != "" ? [var.bastion_ssh_cidr] : ["0.0.0.0/0"]  # WARNING: 0.0.0.0/0 is open to world - restrict in prod!
  }

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-bastion-sg"
    }
  )
}

# Optional: ALB Ingress Controller security group
resource "aws_security_group" "alb_ingress" {
  count = var.create_alb_sg ? 1 : 0

  name        = "${var.project_name}-${var.environment}-alb-ingress-sg"
  description = "Security group for ALB ingress controller"
  vpc_id      = var.vpc_id

  # HTTP from internet
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS from internet
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-alb-ingress-sg"
    }
  )
}
