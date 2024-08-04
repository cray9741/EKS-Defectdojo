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
  depends_on = [
    kubernetes_namespace.defectdojo, 
    module.eks, 
    kubectl_manifest.defectdojoregistrykey
  ]
  values = [
    "${file("../helm_charts/defectdojo/values.yaml")}"
  ]
}

 resource "helm_release" "cert-manager" {
  create_namespace = true
  namespace  = "cert-manager"
  wait_for_jobs = true
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "1.15.0"
  depends_on = [kubernetes_namespace.cert-manager, module.eks]
    set {
    name  = "crds.enabled"
    value = "true"
  }
 }


