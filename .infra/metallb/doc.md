# METALLB

## Using kube-proxy in IPVS mode

### sing kube-proxy in IPVS mode, since Kubernetes v1.14.2 you have to enable strict ARP mode.

### You can achieve this by editing kube-proxy config in current cluster:

`kubectl edit configmap -n kube-system kube-proxy`

## and change it like below!.

`apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: "ipvs"
ipvs:
  strictARP: true`