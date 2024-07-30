resource "kubectl_manifest" "job-manager" {
  yaml_body = <<YAML
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: job-manager
rules:
- apiGroups: ["batch"]
  resources: ["jobs", "jobs/status"]
  verbs: ["create", "get", "list", "watch", "update", "patch", "delete"]
YAML

  depends_on = [helm_release.defectdojo]
}
