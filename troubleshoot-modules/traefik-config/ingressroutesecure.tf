# resource "kubectl_manifest" "IngressRouteSecure" {
#   yaml_body = <<YAML
# apiVersion: traefik.io/v1alpha1
# kind: IngressRoute
# metadata:
#   name: defectdojo-app-secure
#   namespace: defectdojo
# spec:
#   entryPoints:
#     - websecure
#   routes:
#     - match: Host(`defectdojo.cloudlockops.io`)
#       kind: Rule
#       middlewares:
#         - name: secure-headers
#           namespace: defectdojo
#       services:
#         - name: defectdojo-django
#           namespace: defectdojo
#           port: http
#   tls:
#     secretName: defectdojo-tls
# YAML

#   depends_on = [helm_release.traefik]
# }