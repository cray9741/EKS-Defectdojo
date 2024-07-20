resource "kubectl_manifest" "cloudflare-token" {
    yaml_body = <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: cloudflare-api-token
  namespace: cert-manager
type: Opaque
stringData:
  api-token: g1g0DiUyNr_W3zNzqQOshll9e_cvtY-YdOHv2bxE
YAML
}