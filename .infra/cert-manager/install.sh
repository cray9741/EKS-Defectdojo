#!/bin/sh
helm repo add jetstack https://charts.jetstack.io --force-update
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version v1.15.3 \
  --create-namespace \
  --set installCRDs=true