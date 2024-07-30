
#setup metric server
# resource "helm_release" "metrics_server_caml" {
#   namespace  = "kube-system"
#   name       = "metrics-server"
#   chart      = "metrics-server"
#   version    = "3.12.0"
#   repository = "https://kubernetes-sigs.github.io/metrics-server/"
#   depends_on = [module.eks]
# }

# module "eks-cluster-autoscaler" {
#   source  = "lablabs/eks-cluster-autoscaler/aws"
#   version = "2.2.0"
#   cluster_identity_oidc_issuer     = module.eks.cluster_oidc_issuer_url
#   cluster_identity_oidc_issuer_arn = module.eks.oidc_provider_arn
#   cluster_name                     = var.eks_cluster_name
#   depends_on                       = [module.eks]
# }

resource "helm_release" "traefik" {
  create_namespace = true
  namespace  = "traefik"
  name       = "traefik"
  chart      = "traefik"
  version    = "28.2.0"
  repository = "https://helm.traefik.io/traefik"
  depends_on = [module.eks]
  set {
    name  = "additionalArguments"
    value = "{--providers.kubernetesingress.ingressendpoint.publishedservice=traefik/traefik}"
  }
 }

 resource "helm_release" "defectdojo" {
  create_namespace = true
  namespace  = "defectdojo"
  name       = "defectdojo"
  chart      = "defectdojo"
  wait = false
 # version    = "3.12.0"
  repository = "https://raw.githubusercontent.com/DefectDojo/django-DefectDojo/helm-charts"
  depends_on = ["kubernetes_namespace.defectdojo", "module.eks", "kubectl_manifest.cert-manager-webhook-ca", "kubectl_manifest.defectdojo-tls", "kubectl_manifest.cert-manager-webhook-validating", "kubectl_manifest.cert-manager-webhook-mutating"]
  values = [
    "${file("../helm_charts/defectdojo/values.yaml")}" ]
}


 resource "helm_release" "cert-manager" {
  create_namespace = true
  namespace  = "cert-manager"
  wait_for_jobs = true
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "1.15.0"
  depends_on = ["kubernetes_namespace.cert-manager", "module.eks", "kubectl_manifest.IngressRoute", "kubectl_manifest.IngressRouteSecure", "kubectl_manifest.Middleware", "kubectl_manifest.TLSOption"]
    set {
    name  = "crds.enabled"
    value = "true"
  }
 }


