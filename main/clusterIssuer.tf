resource "kubectl_manifest" "ClusterIssuer" {
  depends_on = [helm_release.cert-manager]
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    email: chjackson3rd@gmail.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - dns01:
        cloudflare:
          email: chjackson3rd@gmail.com
          apiKeySecretRef:
            name: cloudflare-api-key
            key: apikey
      selector:
        dnsZones:
        - 'secops-ba.win'
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
    name: letsencrypt-staging
    kind: ClusterIssuer
  commonName: defectdojo.secops-ba.win
  dnsNames:
  - defectdojo.secops-ba.win
YAML
}
