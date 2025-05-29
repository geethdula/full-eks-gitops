#creating EKS cluster IAM role
resource "aws_iam_role" "eks" {
  name = "${local.env}-${local.eks_name}-eks-cluster"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

#creating EKS cluster IAM role policy attachment this will attach above role to the AmazonEKSClusterPolicy
resource "aws_iam_role_policy_attachment" "eks" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks.name
}

# Additional security group for EKS API
resource "aws_security_group" "eks_api" {
  name        = "${local.env}-${local.eks_name}-api-sg"
  description = "Security group for EKS API"
  vpc_id      = aws_vpc.main.id

  # Restrict egress to only what's necessary
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow outbound HTTPS for API server"
  }
  egress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow outbound Kubelet API"
  }
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow outbound DNS"
  }
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow outbound DNS over UDP"
  }

  tags = {
    Name                                                   = "${local.env}-${local.eks_name}-api-sg"
    Terraform                                              = "true"
    Environment                                            = local.env
    "kubernetes.io/cluster/${local.env}-${local.eks_name}" = "owned"
    "aws:eks:cluster-name"                                 = "${local.env}-${local.eks_name}"
  }
}

resource "aws_eks_cluster" "eks" {
  name                          = "${local.env}-${local.eks_name}"
  version                       = local.eks_version
  role_arn                      = aws_iam_role.eks.arn
  bootstrap_self_managed_addons = true # Enable self-managed add-ons


  # Enable logging for the cluster
  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  vpc_config {
    endpoint_private_access = true # Enable private access to the API server only inside the VPC
    endpoint_public_access  = true # Enable/Disable public access

    # Restrict public access to specific CIDR blocks if needed
    # public_access_cidrs = ["YOUR_IP_ADDRESS/32"]

    security_group_ids = [
      aws_security_group.eks_api.id
    ]

    # Use public subnets for dev, private subnets for staging and prod
    subnet_ids = local.env == "dev" ? [
      aws_subnet.public_zone1.id,
      aws_subnet.public_zone2.id
      ] : [
      aws_subnet.private_zone1.id,
      aws_subnet.private_zone2.id
    ]
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [aws_iam_role_policy_attachment.eks]

  tags = {
    Name        = "${local.env}-${local.eks_name}"
    Terraform   = "true"
    Environment = local.env
  }
}