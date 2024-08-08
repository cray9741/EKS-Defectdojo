resource "kubectl_manifest" "ClusterIssuer" {
  depends_on = [helm_release.cert-manager]
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: cloudflare-issuer
spec:
  acme:
    email: chjackson3rd@gmail.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - dns01:
        cloudflare:
          apiKeySecretRef:
            name: cloudflare-api-key
            key: api-key
          email: chjackson3rd@gmail.com
      selector:
        dnsZones:
        - cloudlockops.io
YAML
}

resource "kubectl_manifest" "Certificate" {
  depends_on = [kubectl_manifest.ClusterIssuer]
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: defectdojo-tls
  namespace: defectdojo
spec:
  secretName: defectdojo-tls
  issuerRef:
    name: cloudflare-issuer
    kind: ClusterIssuer
  commonName: defectdojo.cloudlockops.io
  dnsNames:
  - defectdojo.cloudlockops.io
YAML
}
