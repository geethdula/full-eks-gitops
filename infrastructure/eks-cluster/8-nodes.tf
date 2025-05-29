resource "aws_iam_role" "nodes" {
  name = "${local.env}-${local.eks_name}-eks-nodes"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

# This policy now includes AssumeRoleForPodIdentity for the Pod Identity Agent
resource "aws_iam_role_policy_attachment" "amazon_eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "amazon_eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "amazon_ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodes.name
}

#Replace x86_64 in the parameter name below with arm64 to retrieve the ARM version.
#Tracking the latest EKS Node Group AMI releases
# data "aws_ssm_parameter" "eks_ami_release_version" {
#   name = "/aws/service/eks/optimized-ami/${aws_eks_cluster.eks.version}/amazon-linux-2023/x86_64/standard/recommended/release_version"
# }

resource "aws_eks_node_group" "general" {
  cluster_name    = aws_eks_cluster.eks.name
  version         = local.eks_version
  node_group_name = "general"
  node_role_arn   = aws_iam_role.nodes.arn
  node_repair_config {
    enabled = true
  }
  # release_version = nonsensitive(data.aws_ssm_parameter.eks_ami_release_version.value)
  disk_size = 50
  # Use public subnets for dev, private subnets for staging and prod
  subnet_ids = local.env == "dev" ? [
    aws_subnet.public_zone1.id,
    aws_subnet.public_zone2.id
    ] : [
    aws_subnet.private_zone1.id,
    aws_subnet.private_zone2.id
  ]
  remote_access {
    ec2_ssh_key               = local.bastion_key
    source_security_group_ids = [aws_security_group.node_ssh_access.id]
  }

  capacity_type  = "SPOT"
  instance_types = ["t3a.medium"]

  scaling_config {
    desired_size = 2
    max_size     = 8
    min_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    role = "general"
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_eks_cluster.eks,
    aws_iam_role_policy_attachment.amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.amazon_eks_cni_policy,
    aws_iam_role_policy_attachment.amazon_ec2_container_registry_read_only,
  ]

  #You can utilize the generic Terraform resource lifecycle configuration block with ignore_changes to create 
  #an EKS Node Group with an initial size of running instances, then ignore any changes to that count caused 
  #externally (e.g., Application Autoscaling).
  # Allow external changes without Terraform plan difference
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}