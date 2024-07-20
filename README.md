# Test Repository

## Prerequisites

```sh
# Configure AWS CLI
aws configure

# Install Required Tools
# Ensure you have the following tools installed on your machine:
# - Terraform: https://www.terraform.io/downloads
# - Helm: https://helm.sh/docs/intro/install/
# - kubectl: https://kubernetes.io/docs/tasks/tools/install-kubectl/

# Add Helm Repositories
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add stable https://charts.helm.sh/stable
helm repo add gpu-helm-charts https://nvidia.github.io/gpu-monitoring-tools/helm-charts
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo add aquasecurity https://aquasecurity.github.io/helm-charts/
helm repo add traefik https://helm.traefik.io/traefik
helm repo add jetstack https://charts.jetstack.io
helm repo add defectdojo https://raw.githubusercontent.com/DefectDojo/django-DefectDojo/helm-charts
```

## Terraform Setup
```sh
# Navigate to the ./main directory
cd main

# Initialize Terraform
terraform init

# You should see a message like:
# Terraform has been successfully initialized!
#
# You may now begin working with Terraform. Try running "terraform plan" to see
# any changes that are required for your infrastructure. All Terraform commands
# should now work.
#
# If you ever set or change modules or backend configuration for Terraform,
# rerun this command to reinitialize your working directory. If you forget, other
# commands will detect it and remind you to do so if necessary.

# Plan Terraform Deployment
terraform plan -var-file="../tfvars/nonprod/nonprod.tfvars"

# Apply Terraform Deployment
terraform apply -var-file="../tfvars/nonprod/nonprod.tfvars" -auto-approve
```
## Access EKS Cluster
```sh
# Update your kubeconfig to access the EKS cluster
aws eks update-kubeconfig --region us-east-2 --name legion-nonprod

# Check active pods
kubectl get po -A
```
## Destroy Infrastructure
```sh
# Destroy all resources created by Terraform
terraform destroy -var-file="../tfvars/nonprod/nonprod.tfvars" -auto-approve
```