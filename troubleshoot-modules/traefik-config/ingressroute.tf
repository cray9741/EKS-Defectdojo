# resource "kubectl_manifest" "IngressRoute" {
#   yaml_body = <<YAML
# apiVersion: traefik.io/v1alpha1
# kind: IngressRoute
# metadata:
#   name: defectdojo-app
#   namespace: defectdojo
# spec:
#   entryPoints:
#     - web
#   routes:
#     - match: Host(`defectdojo.cloudlockops.io`)
#       kind: Rule
#       middlewares:
#         - name: https-redirect
#           namespace: defectdojo
#         - name: secure-headers
#           namespace: defectdojo
#       services:
#         - name: defectdojo-django
#           namespace: defectdojo
#           port: http
# YAML

#   depends_on = [helm_release.traefik]
# }
