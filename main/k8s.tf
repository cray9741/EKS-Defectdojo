# resource "kubernetes_namespace" "trivy" {
#   count   = var.env == "nonprod" ? 1 : 0
#   metadata {
#     name = "trivy"
#   }
# }

# resource "kubernetes_namespace" "traefik" {
#   count   = var.env == "nonprod" ? 1 : 0
#   metadata {
#     name = "traefik"
#   }
# }

# resource "kubernetes_namespace" "defectdojo" {
#   count   = var.env == "nonprod" ? 1 : 0
#   metadata {
#     name = "defectdojo"
#   }
# }

# resource "kubernetes_namespace" "checkov" {
#   count   = var.env == "nonprod" ? 1 : 0
#   metadata {
#     name = "checkov"
#   }
# }

# resource "kubernetes_namespace" "cert-manager" {
#   count   = var.env == "nonprod" ? 1 : 0
#   metadata {
#     name = "cert-manager"
#   }
# }



# module "eks-alb-ingress" {
#   source  = "lablabs/eks-alb-ingress/aws"
#   version = "0.6.0"
#   cluster_identity_oidc_issuer     = module.eks.cluster_oidc_issuer_url
#   cluster_identity_oidc_issuer_arn = module.eks.oidc_provider_arn
#   cluster_name = var.eks_cluster_name
#   enabled = true
# }



# module "alb_controller" {
#   source                                     = "../alb"
#   k8s_cluster_type                           = "eks"
#   k8s_namespace                              = "kube-system"
#   aws_region_name                            = var.region
#   k8s_cluster_name                           = var.eks_cluster_name
#   aws_load_balancer_controller_chart_version = "1.7.1"
#   depends_on                                 = [module.eks]
# }


