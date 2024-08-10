data "aws_caller_identity" "current" {}

data "aws_eks_cluster_auth" "this" {
  name = var.eks_cluster_name
}

#setup kms key for eks secrets
resource "aws_kms_key" "eks_kms_key" {
  description             = "KMS key for EKS secrets"
  deletion_window_in_days = var.kms_deletion_window_in_days
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}




###
### kubernetes manifest's
###

#============= Cert Manager TLS ==============#


#============= Cert Manager ==============#



#============= Service Accounts ==============#
resource "kubectl_manifest" "scan-account" {
  yaml_body = <<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: scan-account
  namespace: default
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::623045223656:role/eks-nonprod-s3-2

YAML
}

#============= EKS Roles ==============#
resource "kubectl_manifest" "job-manager" {
  yaml_body = <<YAML
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  namespace: default
  name: job-manager
rules:
- apiGroups: ["batch"]
  resources: ["jobs", "jobs/status"]
  verbs: ["create", "get", "list", "watch", "update", "patch", "delete"]

YAML
}

#============= EKS Role Bindings ==============#
resource "kubectl_manifest" "job-manager-binding" {
  yaml_body = <<YAML
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: job-manager-binding
subjects:
- kind: ServiceAccount
  name: defectdojo
  namespace: defectdojo
roleRef:
  kind: ClusterRole
  name: job-manager
  apiGroup: rbac.authorization.k8s.io

YAML
  depends_on = [kubectl_manifest.scan-account, kubectl_manifest.job-manager]
}

#============= Defectdojo Docker Registry Key ==============#
resource "kubectl_manifest" "defectdojoregistrykey" {
  yaml_body = <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: defectdojoregistrykey
  namespace: defectdojo
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: eyJhdXRocyI6eyJodHRwczovL2luZGV4LmRvY2tlci5pby92MS8iOnsidXNlcm5hbWUiOiJ0cmF5M3JkIiwicGFzc3dvcmQiOiJ+MTQxTzkwbGQ5NzQxTm9ydGhlcm4iLCJlbWFpbCI6ImNyYXk5NzQxQG91dGxvb2suY29tIiwiYXV0aCI6ImRISmhlVE55WkRwK01UUXhUemt3YkdRNU56UXhUbTl5ZEdobGNtND0ifX19

YAML
}

#============= Traefik  ==============#
resource "kubectl_manifest" "IngressRouteSecure" {
  yaml_body = <<YAML
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: defectdojo-app-secure
  namespace: defectdojo
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`defectdojo.cloudlockops.io`)
      kind: Rule
      middlewares:
        - name: secure-headers
          namespace: defectdojo
      services:
        - name: defectdojo-django
          namespace: defectdojo
          port: http
  tls:
    secretName: defectdojo-tls

YAML
depends_on = [helm_release.traefik]
}

resource "kubectl_manifest" "IngressRouteSecure" {
  yaml_body = <<YAML
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: defectdojo-app-internal
  namespace: defectdojo
spec:
  entryPoints:
    - web
  routes:
    - match: Host(`defectdojo-django.defectdojo.svc.cluster.local`)
      kind: Rule
      services:
        - name: defectdojo-django
          namespace: defectdojo
          port: http
YAML
depends_on = [helm_release.traefik]
}

resource "kubectl_manifest" "IngressRoute" {
  yaml_body = <<YAML
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: defectdojo-app
  namespace: defectdojo
spec:
  entryPoints:
    - web
  routes:
    - match: Host(`defectdojo.cloudlockops.io`)
      kind: Rule
      middlewares:
        - name: https-redirect
          namespace: defectdojo
        - name: secure-headers
          namespace: defectdojo
      services:
        - name: defectdojo-django
          namespace: defectdojo
          port: http

YAML
depends_on = [helm_release.traefik]
}



resource "kubectl_manifest" "secure_headers" {
  yaml_body = <<YAML
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: secure-headers
  namespace: defectdojo
spec:
  headers:
    customRequestHeaders:
      X-Forwarded-For: "{clientIP}"
      X-Forwarded-Proto: "https"
    stsSeconds: 31536000
    stsIncludeSubdomains: true
    stsPreload: true

YAML
depends_on = [helm_release.traefik]
}


#============= Checkov Cronjobs ==============#
resource "kubectl_manifest" "checkov-scan-cronjob" {
  yaml_body = <<YAML
apiVersion: batch/v1
kind: CronJob
metadata:
  name: checkov-scan-s3-upload-cronjob
spec:
  schedule: "0 0 * * *"  # Runs at 12:00 AM
  jobTemplate:
    spec:
      ttlSecondsAfterFinished: 30
      backoffLimit: 4
      template:
        spec:
          serviceAccountName: scan-account
          containers:
            - name: checkov-scan-s3-upload-container
              image: tray3rd/checkov-scan-s3-upload:latest
              env:
                - name: S3_BUCKET
                  value: "tools-bucket-cloudranger-30293812"
                - name: S3_FOLDER
                  value: "checkov"
                - name: AWS_DEFAULT_REGION
                  value: "us-east-1"
                - name: SEARCH_DIRECTORY
                  value: "/output"
              resources:
                requests:
                  memory: "2Gi"
                  cpu: "1"
                limits:
                  memory: "4Gi"
                  cpu: "2"
          restartPolicy: Never

YAML
}

resource "kubectl_manifest" "checkov-dojo-cronjob" {
  yaml_body = <<YAML
apiVersion: batch/v1
kind: CronJob
metadata:
  name: checkov-cronjob
spec:
  schedule: "30 0 * * *"  # Runs at 12:30 AM
  jobTemplate:
    spec:
      ttlSecondsAfterFinished: 30
      template:
        spec:
          serviceAccountName: scan-account
          containers:
            - name: checkov-push
              image: tray3rd/checkovdojo:latest 
              env:
                - name: DOJO_PROD_ID
                  value: "1"
                - name: S3_BUCKET
                  value: "tools-bucket-cloudranger-30293812"
                - name: S3_FOLDER
                  value: "checkov"
                - name: S3_PROCESSED
                  value: "processed/checkov"
                - name: AWS_DEFAULT_REGION
                  value: "us-east-1"
                - name: AWS_REGION
                  value: "us-east-1"
              command: ["python"]
              args: ["entrypoint.py"]
          restartPolicy: Never

YAML
}

resource "kubectl_manifest" "checkov-rr-cronjob" {
  yaml_body = <<YAML
apiVersion: batch/v1
kind: CronJob
metadata:
  name: checkov-rr-cronjob
spec:
  schedule: "0 1 * * *"  # Runs at 1:00 AM
  jobTemplate:
    spec:
      ttlSecondsAfterFinished: 30
      backoffLimit: 4
      template:
        spec:
          serviceAccountName: scan-account
          containers:
            - name: checkov-rr
              image: tray3rd/checkovrr:latest
              imagePullPolicy: Always
              env:
                - name: AWS_REGION
                  value: "us-east-1"
              command: ["python", "entrypoint.py"]
          restartPolicy: Never

YAML
}

#============= Kubescape Cronjobs ==============#
resource "kubectl_manifest" "kubescape-scan-cronjob" {
  yaml_body = <<YAML
apiVersion: batch/v1
kind: CronJob
metadata:
  name: kubescape-scan-s3-upload-cronjob
spec:
  schedule: "0 0 * * *"  # Runs at 12:00 AM
  jobTemplate:
    spec:
      ttlSecondsAfterFinished: 30
      backoffLimit: 4
      template:
        spec:
          serviceAccountName: scan-account
          containers:
            - name: kubescape-scan-s3-upload-container
              image: tray3rd/kubescape-scan-s3-upload:latest
              env:
                - name: S3_BUCKET
                  value: "tools-bucket-cloudranger-30293812"
                - name: S3_FOLDER
                  value: "kubescape"
                - name: AWS_DEFAULT_REGION
                  value: "us-east-1"
                - name: SEARCH_DIRECTORY
                  value: "/output"
              resources:
                requests:
                  memory: "2Gi"
                  cpu: "1"
                limits:
                  memory: "4Gi"
                  cpu: "2"
          restartPolicy: Never

YAML
}

resource "kubectl_manifest" "kubescape-dojo-cronjob" {
  yaml_body = <<YAML
apiVersion: batch/v1
kind: CronJob
metadata:
  name: kubescape-push-cronjob
spec:
  schedule: "30 0 * * *"  # Runs at 12:30 AM
  jobTemplate:
    spec:
      ttlSecondsAfterFinished: 30
      template:
        spec:
          serviceAccountName: scan-account
          containers:
            - name: kubescape-push
              image: tray3rd/kubescapedojo:latest  # Replace with your Docker image name
              env:
                - name: DOJO_PROD_ID
                  value: "1"
                - name: S3_BUCKET
                  value: "tools-bucket-cloudranger-30293812"
                - name: S3_FOLDER
                  value: "kubescape"
                - name: S3_PROCESSED
                  value: "processed/kubescape"
                - name: AWS_DEFAULT_REGION
                  value: "us-east-1"
                - name: AWS_REGION
                  value: "us-east-1"
              command: ["python"]
              args: ["entrypoint.py"]
          restartPolicy: Never

YAML
}

resource "kubectl_manifest" "kubescape-rr-cronjob" {
  yaml_body = <<YAML
apiVersion: batch/v1
kind: CronJob
metadata:
  name: kubescape-rr-cronjob
spec:
  schedule: "0 1 * * *"  # Runs at 1:00 AM
  jobTemplate:
    spec:
      ttlSecondsAfterFinished: 30
      backoffLimit: 4
      template:
        spec:
          containers:
            - name: kubescape-rr
              image: tray3rd/kubescaperr:latest
              imagePullPolicy: Always
              env:
                - name: AWS_REGION
                  value: "us-east-1"
              command: ["python", "entrypoint.py"]
          restartPolicy: Never

YAML
}

#============= Dependabot Cronjobs ==============#
resource "kubectl_manifest" "dependabot-dojo-cronjob" {
  yaml_body = <<YAML
apiVersion: batch/v1
kind: CronJob
metadata:
  name: dependabot-push-cronjob
spec:
  schedule: "30 0 * * *"  # Runs at 12:30 AM
  jobTemplate:
    spec:
      ttlSecondsAfterFinished: 30
      template:
        spec:
          serviceAccountName: scan-account
          containers:
            - name: dependabot-push
              image: tray3rd/dependabotdojo:latest  # Replace with your Docker image name
              env:
                - name: DOJO_PROD_ID
                  value: "1"
                - name: S3_BUCKET
                  value: "tools-bucket-cloudranger-30293812"
                - name: S3_FOLDER
                  value: "dependabot"
                - name: S3_PROCESSED
                  value: "processed/dependabot"
                - name: AWS_DEFAULT_REGION
                  value: "us-east-1"
                - name: AWS_REGION
                  value: "us-east-1"
          restartPolicy: Never

YAML
}

resource "kubectl_manifest" "dependabot-rr-cronjob" {
  yaml_body = <<YAML
apiVersion: batch/v1
kind: CronJob
metadata:
  name: dependabot-rr-cronjob
spec:
  schedule: "0 1 * * *"  # Runs at 1:00 AM
  jobTemplate:
    spec:
      ttlSecondsAfterFinished: 30
      backoffLimit: 4
      template:
        spec:
          containers:
            - name: dependabot-rr
              image: tray3rd/dependabotrr:latest
              imagePullPolicy: Always
              env:
                - name: AWS_REGION
                  value: "us-east-1"
              command: ["python", "entrypoint.py"]
          restartPolicy: Never

YAML
}

#============= Prowler Cronjobs ==============#
resource "kubectl_manifest" "prowler-scan-cronjob" {
  yaml_body = <<YAML
apiVersion: batch/v1
kind: CronJob
metadata:
  name: prowler-scan-s3-upload-cronjob
spec:
  schedule: "0 0 * * *"  # Runs at 12:00 AM
  jobTemplate:
    spec:
      ttlSecondsAfterFinished: 30
      backoffLimit: 4
      template:
        spec:
          serviceAccountName: scan-account
          containers:
            - name: prowler-scan-s3-upload-container
              image: tray3rd/prowler-scan-s3-upload:latest
              env:
                - name: S3_BUCKET
                  value: "tools-bucket-cloudranger-30293812"
                - name: S3_FOLDER
                  value: "prowler"
                - name: AWS_DEFAULT_REGION
                  value: "us-east-1"
                - name: SEARCH_DIRECTORY
                  value: "/output"
              resources:
                requests:
                  memory: "2Gi"
                  cpu: "1"
                limits:
                  memory: "4Gi"
                  cpu: "2"
          restartPolicy: Never

YAML
}

resource "kubectl_manifest" "prowler-dojo-cronjob" {
  yaml_body = <<YAML
apiVersion: batch/v1
kind: CronJob
metadata:
  name: prowler-push-cronjob
spec:
  schedule: "30 0 * * *"  # Runs at 12:30 AM
  jobTemplate:
    spec:
      ttlSecondsAfterFinished: 30
      template:
        spec:
          serviceAccountName: scan-account
          containers:
            - name: prowler-push
              image: tray3rd/prowlerdojo:latest  # Replace with your Docker image name
              env:
                - name: DOJO_PROD_ID
                  value: "1"
                - name: S3_BUCKET
                  value: "tools-bucket-cloudranger-30293812"
                - name: S3_FOLDER
                  value: "prowler"
                - name: S3_PROCESSED
                  value: "processed/prowler"
                - name: AWS_DEFAULT_REGION
                  value: "us-east-1"
                - name: AWS_REGION
                  value: "us-east-1"
              command: ["python"]
              args: ["entrypoint.py"]
          restartPolicy: Never

YAML
}

resource "kubectl_manifest" "prowler-rr-cronjob" {
  yaml_body = <<YAML
apiVersion: batch/v1
kind: CronJob
metadata:
  name: prowler-rr-cronjob
spec:
  schedule: "0 1 * * *"  # Runs at 1:00 AM
  jobTemplate:
    spec:
      ttlSecondsAfterFinished: 30
      backoffLimit: 4
      template:
        spec:
          containers:
            - name: prowler-rr
              image: tray3rd/prowlerrr:latest
              imagePullPolicy: Always
              env:
                - name: AWS_REGION
                  value: "us-east-1"
              command: ["python", "entrypoint.py"]
          restartPolicy: Never

YAML
}

#============= Security Hub Cronjobs ==============#
resource "kubectl_manifest" "sechub-dojo-cronjob" {
  yaml_body = <<YAML
apiVersion: batch/v1
kind: CronJob
metadata:
  name: sechub-push-cronjob
spec:
  schedule: "30 0 * * *"  # Runs at 12:30 AM
  jobTemplate:
    spec:
      ttlSecondsAfterFinished: 30
      template:
        spec:
          serviceAccountName: scan-account
          containers:
            - name: sechub-push
              image: tray3rd/sechubdojo:latest  # Replace with your Docker image name
              env:
                - name: DOJO_PROD_ID
                  value: "1"
                - name: AWS_DEFAULT_REGION
                  value: "us-east-1"
                - name: AWS_REGION
                  value: "us-east-1"
              command: ["python"]
              args: ["entrypoint.py"]
          restartPolicy: Never

YAML
}

resource "kubectl_manifest" "sechub-rr-cronjob" {
  yaml_body = <<YAML
apiVersion: batch/v1
kind: CronJob
metadata:
  name: sechub-rr-cronjob
spec:
  schedule: "0 1 * * *"  # Runs at 1:00 AM
  jobTemplate:
    spec:
      ttlSecondsAfterFinished: 30
      backoffLimit: 4
      template:
        spec:
          serviceAccountName: scan-account
          containers:
            - name: sechub-rr
              image: tray3rd/sechubrr:latest
              imagePullPolicy: Always
              env:
                - name: AWS_REGION
                  value: "us-east-1"
              command: ["python", "entrypoint.py"]
          restartPolicy: Never

YAML
}

#============= Trufflehog Cronjobs ==============#
resource "kubectl_manifest" "trufflehog-scan-cronjob" {
  yaml_body = <<YAML
apiVersion: batch/v1
kind: CronJob
metadata:
  name: trufflehog-scan-s3-upload-cronjob
spec:
  schedule: "0 0 * * *"  # Runs at 12:00 AM
  jobTemplate:
    spec:
      ttlSecondsAfterFinished: 30
      backoffLimit: 4
      template:
        spec:
          serviceAccountName: scan-account
          containers:
            - name: trufflehog-scan-s3-upload-container
              image: tray3rd/trufflehog-scan-s3-upload:latest
              env:
                - name: S3_BUCKET
                  value: "tools-bucket-cloudranger-30293812"
                - name: S3_FOLDER
                  value: "trufflehog"
                - name: AWS_DEFAULT_REGION
                  value: "us-east-1"
                - name: SEARCH_DIRECTORY
                  value: "/output"
              resources:
                requests:
                  memory: "2Gi"
                  cpu: "1"
                limits:
                  memory: "4Gi"
                  cpu: "2"
          restartPolicy: Never

YAML
}

resource "kubectl_manifest" "trufflehog-dojo-cron" {
  yaml_body = <<YAML
apiVersion: batch/v1
kind: CronJob
metadata:
  name: trufflehog-push-cronjob
spec:
  schedule: "30 0 * * *"  # Runs at 12:30 AM
  jobTemplate:
    spec:
      ttlSecondsAfterFinished: 30
      template:
        spec:
          serviceAccountName: scan-account
          containers:
            - name: trufflehog-push
              image: tray3rd/trufflehogdojo:latest  # Replace with your Docker image name
              env:
                - name: DOJO_PROD_ID
                  value: "1"
                - name: S3_BUCKET
                  value: "tools-bucket-cloudranger-30293812"
                - name: S3_FOLDER
                  value: "trufflehog"
                - name: S3_PROCESSED
                  value: "processed/trufflehog"
                - name: AWS_DEFAULT_REGION
                  value: "us-east-1"
                - name: AWS_REGION
                  value: "us-east-1"
              command: ["python"]
              args: ["entrypoint.py"]
          restartPolicy: Never

YAML
}

resource "kubectl_manifest" "trufflehog-rr-cronjob" {
  yaml_body = <<YAML
apiVersion: batch/v1
kind: CronJob
metadata:
  name: trufflehog-rr-cronjob
spec:
  schedule: "0 1 * * *"  # Runs at 1:00 AM
  jobTemplate:
    spec:
      ttlSecondsAfterFinished: 30
      backoffLimit: 4
      template:
        spec:
          serviceAccountName: scan-account
          containers:
            - name: trufflehog-rr
              image: tray3rd/trufflehogrr:latest
              imagePullPolicy: Always
              env:
                - name: AWS_REGION
                  value: "us-east-1"
              command: ["python", "entrypoint.py"]
          restartPolicy: Never

YAML
}

#============= Zaproxy Cronjobs ==============#
resource "kubectl_manifest" "zaproxy-scan-cronjob" {
  yaml_body = <<YAML
apiVersion: batch/v1
kind: CronJob
metadata:
  name: zaproxy-scan-s3-upload-cronjob
spec:
  schedule: "0 0 * * *"  # Runs at 12:00 AM
  jobTemplate:
    spec:
      ttlSecondsAfterFinished: 30
      backoffLimit: 4
      template:
        spec:
          serviceAccountName: scan-account
          containers:
            - name: zaproxy-scan-s3-upload-container
              image: tray3rd/zaproxy-scan-s3-upload:latest
              env:
                - name: S3_BUCKET
                  value: "tools-bucket-cloudranger-30293812"
                - name: S3_FOLDER
                  value: "zaproxy"
                - name: AWS_DEFAULT_REGION
                  value: "us-east-1"
              resources:
                requests:
                  memory: "2Gi"
                  cpu: "1"
                limits:
                  memory: "4Gi"
                  cpu: "2"
          restartPolicy: Never

YAML
}

resource "kubectl_manifest" "zaproxy-dojo-cronjob" {
  yaml_body = <<YAML
apiVersion: batch/v1
kind: CronJob
metadata:
  name: zaproxy-push-cronjob
spec:
  schedule: "30 0 * * *"  # Runs at 12:30 AM
  jobTemplate:
    spec:
      ttlSecondsAfterFinished: 30
      template:
        spec:
          serviceAccountName: scan-account
          containers:
            - name: zaproxy-push
              image: tray3rd/zaproxydojo:latest  # Replace with your Docker image name
              env:
                - name: DOJO_PROD_ID
                  value: "1"
                - name: S3_BUCKET
                  value: "tools-bucket-cloudranger-30293812"
                - name: S3_FOLDER
                  value: "zaproxy"
                - name: S3_PROCESSED
                  value: "processed/zaproxy"
                - name: AWS_DEFAULT_REGION
                  value: "us-east-1"
                - name: AWS_REGION
                  value: "us-east-1"
              command: ["python"]
              args: ["entrypoint.py"]
          restartPolicy: Never

YAML
}

resource "kubectl_manifest" "zaproxy_rr_cronjob" {
  yaml_body = <<YAML
apiVersion: batch/v1
kind: CronJob
metadata:
  name: zaproxy-rr-cronjob
spec:
  schedule: "0 1 * * *"  # Runs at 1:00 AM
  jobTemplate:
    spec:
      ttlSecondsAfterFinished: 30
      backoffLimit: 4
      template:
        spec:
          serviceAccountName: scan-account
          containers:
            - name: zaproxy-rr
              image: tray3rd/zaproxyrr:latest
              imagePullPolicy: Always
              env:
                - name: AWS_REGION
                  value: "us-east-1"
              command: ["python", "entrypoint.py"]
          restartPolicy: Never

YAML
}

#============= KMS key to encrypt EKS EBS ==============#
module "ebs_kms_key" {
  source      = "terraform-aws-modules/kms/aws"
  version     = "2.2.0"
  description = "Customer managed key to encrypt EKS managed node group volumes"
  # Policy
  key_administrators = [
    data.aws_caller_identity.current.arn
  ]
  key_service_roles_for_autoscaling = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling",
  ]
  # Aliases
  aliases = ["eks/${var.eks_cluster_name}/ebs"]
}

data "tls_certificate" "eks" {
  url = module.eks.cluster_oidc_issuer_url
}

#============= EKS Cluster ==============#
module "eks" {

  source  = "terraform-aws-modules/eks/aws"
  version = "18.31.2"

  cluster_name    = var.eks_cluster_name
  cluster_version = var.eks_cluster_version

  vpc_id                    = module.vpc.vpc_id
  subnet_ids                = module.vpc.private_subnets

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  cluster_enabled_log_types       = var.eks_cluster_log_types

#  create_aws_auth_configmap = true
  manage_aws_auth_configmap = true
  custom_oidc_thumbprints   = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]

  cluster_security_group_additional_rules = {
    eks_sg = {
      description = "All from VPC"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      cidr_blocks = [var.vpc_cidr]
    }
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }
  node_security_group_additional_rules = {
    ingress_allow_access_from_control_plane = {
      type                          = "ingress"
      protocol                      = "tcp"
      from_port                     = 9443
      to_port                       = 9443
      source_cluster_security_group = true
      description                   = "Allow access from control plane to webhook port of AWS load balancer controller"
    }
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description = "Node all egress"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  cluster_encryption_config = [
    {
      provider_key_arn = aws_kms_key.eks_kms_key.arn
      resources        = ["secrets"]
    }
  ]

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      service_account_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.env}-ebs-csi-controller"
      resolve_conflicts        = "PRESERVE"
    }
  }

  eks_managed_node_groups = {

    eks_managed_node1 = {
      iam_role_name         = var.iam_role_name
      min_size              = var.eks_cluster_min_size
      max_size              = var.eks_cluster_max_size
      desired_size          = var.eks_cluster_des_size
      ami_type              = var.eks_cluster_ami_type
      instance_types        = [var.eks_cluster_instance_type]
      capacity_type         = var.eks_cluster_capacity
      depends_on            = [aws_iam_policy.policy-workernode.arn, aws_iam_policy.policy-jira.arn]
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 80
            volume_type           = "gp3"
            encrypted             = true
            kms_key_id            = "arn:aws:kms:${var.region}:${data.aws_caller_identity.current.account_id}:alias/eks/${var.eks_cluster_name}/ebs"
            delete_on_termination = true
          }
        }
      }
      iam_role_additional_policies = [
        "arn:aws:iam::aws:policy/CloudWatchFullAccessV2",
        "arn:aws:iam::623045223656:policy/workernode",
        "arn:aws:iam::623045223656:policy/jira-perms",
      ]

      tags = {
        "k8s.io/cluster-autoscaler/${var.eks_cluster_name}" = "owned"
        "k8s.io/cluster-autoscaler/enabled"                 = "TRUE"
      }

      update_config = {
        max_unavailable_percentage = var.eks_max_unavailable_percentage
      }

    }

  }

  aws_auth_roles = var.eks_map_roles
  aws_auth_users = var.eks_map_users
}

