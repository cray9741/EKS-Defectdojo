# resource "kubectl_manifest" "TLSOption" {
#   yaml_body = <<YAML
# apiVersion: traefik.io/v1alpha1
# kind: TLSOption
# metadata:
#   name: default
#   namespace: traefik
# spec:
#   minVersion: VersionTLS12

# YAML

#   depends_on = [helm_release.traefik]
# }