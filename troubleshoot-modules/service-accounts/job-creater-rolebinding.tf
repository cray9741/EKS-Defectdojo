resource "kubectl_manifest" "job-manager-binding" {
  yaml_body = <<YAML
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: job-manager-binding
  namespace: default
subjects:
- kind: ServiceAccount
  name: scan-account
  namespace: default
roleRef:
  kind: Role
  name: job-manager
  apiGroup: rbac.authorization.k8s.io
YAML

  depends_on = [helm_release.defectdojo]
}
