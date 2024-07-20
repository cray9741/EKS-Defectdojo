resource "kubectl_manifest" "cloudflare_token" {
  yaml_body = <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: cloudflare-api-token
  namespace: cert-manager
type: Opaque
stringData:
  api-token: 10TFi0Ipf005Ail2nvUx3s5aWB55JFa009UySAdb
YAML

  depends_on = [helm_release.cert-manager]
}
