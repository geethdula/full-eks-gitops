# provider "kubernetes" {
#   host                   = module.eks.cluster_endpoint
#   cluster_ca_certificate = base64decode(aws_eks_cluster.eks.cluster_certificate_authority_data)

#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     command     = "aws"
#     # This requires the awscli to be installed locally where Terraform is executed
#     args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
#   }
# }

# module "karpenter" {
#   source  = "terraform-aws-modules/eks/aws//modules/karpenter"
#   version = "19.20.0"

#   cluster_name                    = aws_eks_cluster.eks.name
#   irsa_oidc_provider_arn          = aws_eks_cluster.eks.oidc_provider_arn
#   irsa_namespace_service_accounts = ["karpenter:karpenter"]

#   create_iam_role      = false
#   iam_role_arn         = aws_iam_role.nodes.iam_role_arn
#   irsa_use_name_prefix = false

#   tags = {
#     "karpenter.sh/discovery"                               = "${local.env}-${local.eks_name}"

#   }
# }
# resource "helm_release" "karpenter" {
#   namespace        = "karpenter"
#   create_namespace = true

#   name                = "karpenter"
#   repository          = "oci://public.ecr.aws/karpenter"
#   repository_username = data.aws_ecrpublic_authorization_token.token.user_name
#   repository_password = data.aws_ecrpublic_authorization_token.token.password
#   chart               = "karpenter"
#   version             = "v0.31.3"

#   set {
#     name  = "settings.aws.clusterName"
#     value = module.eks.cluster_name
#   }

#   set {
#     name  = "settings.aws.clusterEndpoint"
#     value = module.eks.cluster_endpoint
#   }

#   set {
#     name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
#     value = module.karpenter.irsa_arn
#   }

#   set {
#     name  = "settings.aws.defaultInstanceProfile"
#     value = module.karpenter.instance_profile_name
#   }

#   set {
#     name  = "settings.aws.interruptionQueueName"
#     value = module.karpenter.queue_name
#   }
# }

