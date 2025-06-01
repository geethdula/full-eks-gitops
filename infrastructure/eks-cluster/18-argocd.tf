data "aws_eks_cluster_auth" "main" {
 name = aws_eks_cluster.eks.name
}


resource "helm_release" "argocd" {
 depends_on = [aws_eks_node_group.general]
 name       = "argocd"
 repository = "https://argoproj.github.io/argo-helm"
 chart      = "argo-cd"
 version    = "8.0.0"

 namespace = "argocd"

 create_namespace = true

 set {
   name  = "server.service.type"
   value = "NodePort"
 }

}


# data "kubernetes_service" "argocd_server" {
#     provider = kubernetes
#  metadata {
#    name      = "argocd-server"
#    namespace = helm_release.argocd.namespace

#  }
# }
#slGFyAmCE75yyus5