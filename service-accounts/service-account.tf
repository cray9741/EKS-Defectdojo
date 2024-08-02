resource "kubectl_manifest" "scan-account" {
  yaml_body = <<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: scan-account
  namespace: default
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::038810797634:role/<service-account-name>
YAML

  depends_on = [helm_release.defectdojo]
}
