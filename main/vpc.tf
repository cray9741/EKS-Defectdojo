module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.2" #Variables not allowed here in module

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs              = var.az_list
  private_subnets  = var.private_subnets
  public_subnets   = var.public_subnets
  database_subnets = var.db_subnets

  enable_nat_gateway   = var.enable_nat_gateway
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    "kubernetes.io/role/elb"                        = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"               = "1"
  }
}
