resource "kubectl_manifest" "Middleware" {
  yaml_body = <<YAML
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: secure-headers
  namespace: defectdojo
spec:
  headers:
    customRequestHeaders:
      X-Forwarded-For: "{clientIP}"
      X-Forwarded-Proto: "https"
    stsSeconds: 31536000
    stsIncludeSubdomains: true
    stsPreload: true
YAML

  depends_on = [helm_release.traefik]
}