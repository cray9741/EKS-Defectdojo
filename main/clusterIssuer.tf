resource "kubectl_manifest" "ClusterIssuer" {
    depends_on = [helm_release.cert-manager]
    yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: cloudflareissuer
  namespace: cert-manager
spec:
  acme:
    email: vkhachatryan339@gmail.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: cluster-issuer-account-key
    solvers:
    - dns01:
        cloudflare:
          email: vkhachatryan339@gmail.com
          apiTokenSecretRef:
            name: cloudflare-api-token
            key: api-token
YAML
}
         