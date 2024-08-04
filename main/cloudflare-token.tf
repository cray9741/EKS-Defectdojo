resource "kubectl_manifest" "cloudflare_api_key" {
  yaml_body = <<YAML
apiVersion: v1
data:
  api-key: ZGQ0OGI0ZTQwYWE4YmI5OTI3NTliNTI0MWZiMzMwNTJmODEwOQ==
kind: Secret
metadata:
  name: cloudflare-api-key
  namespace: cert-manager
type: Opaque
YAML

  depends_on = [helm_release.cert-manager]
}
