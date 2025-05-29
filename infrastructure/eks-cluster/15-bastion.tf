# Bastion Host Security Group
resource "aws_security_group" "bastion" {
  name        = "${local.env}-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict this to your IP in production
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.env}-bastion-sg"
  }
}

# Bastion Host Instance
resource "aws_instance" "bastion" {
  ami                  = "ami-0af9569868786b23a" # Amazon Linux 2023 AMI or use Ubuntu AMI
  instance_type        = "t3.micro"
  subnet_id            = aws_subnet.public_zone1.id
  key_name             = local.bastion_key # Replace with your key pair name
  iam_instance_profile = aws_iam_instance_profile.bastion.name

  vpc_security_group_ids = [aws_security_group.bastion.id]

  user_data = base64encode(templatefile("${path.module}/scripts/configure-bastion.sh", {
    env                  = local.env
    region               = local.region
    eks_name             = local.eks_name
    KUBECTL_VERSION      = local.kubectl_version
    AWS_IAM_AUTH_VERSION = "0.6.15" # Fixed version for aws-iam-authenticator
  }))

  tags = {
    Name = "${local.env}-bastion"
  }
}

# IAM Role for Bastion
resource "aws_iam_role" "bastion" {
  name = "${local.env}-bastion-role"

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
}

resource "aws_iam_role_policy_attachment" "bastion_eks" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${local.env}-bastion-profile"
  role = aws_iam_role.bastion.name
}

# Allow EKS API access from bastion
resource "aws_security_group_rule" "eks_cluster_ingress_bastion" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_eks_cluster.eks.vpc_config[0].cluster_security_group_id
  source_security_group_id = aws_security_group.bastion.id
  description              = "Allow access from bastion host"
}