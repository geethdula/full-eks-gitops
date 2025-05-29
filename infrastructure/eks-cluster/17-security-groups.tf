# Security group for SSH access to EKS nodes
resource "aws_security_group" "node_ssh_access" {
  name        = "${local.env}-${local.eks_name}-node-ssh-sg"
  description = "Security group for SSH access to EKS nodes"
  vpc_id      = aws_vpc.main.id

  # Allow SSH from specific sources (e.g., bastion host)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr] # Use the workspace-specific VPC CIDR
    description = "Allow SSH from within VPC"
  }

  tags = {
    Name        = "${local.env}-${local.eks_name}-node-ssh-sg"
    Terraform   = "true"
    Environment = local.env
  }
}