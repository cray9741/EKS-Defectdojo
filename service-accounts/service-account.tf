resource "kubectl_manifest" "scan-account" {
  yaml_body = <<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: scan-account 
  namespace: default
YAML

  depends_on = [helm_release.defectdojo]
}
