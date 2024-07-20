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

#KMS key to encrypt EKS EBS
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

#EKS cluster
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
      min_size              = var.eks_cluster_min_size
      max_size              = var.eks_cluster_max_size
      desired_size          = var.eks_cluster_des_size
      ami_type              = var.eks_cluster_ami_type
      instance_types        = [var.eks_cluster_instance_type]
      capacity_type         = var.eks_cluster_capacity
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

}

