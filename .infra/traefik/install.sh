#!/bin/sh

helm repo add traefik https://helm.traefik.io/traefik
helm repo update
helm install --namespace=traefik-system --create-namespace traefik traefik/traefik -f values.yaml
