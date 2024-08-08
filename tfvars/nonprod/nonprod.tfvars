# AWS variables
region                = "us-east-1"
env                   = "nonprod"

#================= VPC =======================#
vpc_name        = "legion-nonprod"
vpc_version     = "5.5.2"
vpc_cidr        = "10.234.0.0/16"
az_list         = ["us-east-1a","us-east-1b","us-east-1c"]
db_subnets      = ["10.234.48.0/21", "10.234.56.0/21", "10.234.64.0/21"]
private_subnets = ["10.234.24.0/21", "10.234.32.0/21", "10.234.40.0/21"]
public_subnets  = ["10.234.0.0/21", "10.234.8.0/21", "10.234.16.0/21"]
enable_nat_gateway = true
enable_dns_hostnames = true
enable_dns_support = true

#================= EKS =======================#
iam_role_name         = "eks_managed_node1"
eks_cluster_version   = "1.29"
eks_cluster_name      = "legion-nonprod"
eks_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
eks_cluster_instance_type    = "t3a.large"
eks_cluster_ami_type          = "AL2_x86_64"
eks_cluster_capacity     = "ON_DEMAND"
eks_cluster_min_size      = "3"
eks_cluster_max_size      = "5"
eks_cluster_des_size      = "3"
eks_max_unavailable_percentage = "50"
eks_map_roles        = [
    {
     rolearn  = "arn:aws:iam::623045223656:role/eks-manage-role-nonprod"
     username = "eks-manage-role-nonprod"
     groups = ["system:masters"]
  },
  
  {  rolearn  = "arn:aws:iam::623045223656:role/eks-nonprod-s3-2"
     username = "scan-account"
     groups = ["system:masters"]
  }
  ]

eks_map_users        = [
    {
      userarn = "arn:aws:iam::623045223656:user/eksuser"
      username = "eksuser"
      groups = ["system:masters"]
  }
  ] 
  
sc_list  = ["1a", "1b", "1c"]


cluster_endpoint_public_access_cidrs = [
  "141.136.91.0/32"
]

#================= WAF =======================#
allowed_cidr_blocks = [
  "100.36.68.167/32"
]

#================= AWS KMS =======================#
kms_deletion_window_in_days = "7"


#================= RDS =======================#
db_engine_version = "8.0"
db_engine = "mysql"
db_identifier = "dev-db-main"
db_family = "mysql8.0"
db_major_engine_version = "8.0" 
db_instance_class = "db.t3.small"
db_name = "dev"
db_port = "3306"
db_allocated_storage = 5
db_max_allocated_storage = 50 
db_storage_encrypted = true
db_maintenance_window = "Mon:00:00-Mon:03:00"
db_backup_window = "03:00-06:00"
db_backup_retention_period = "3"
db_skip_final_snapshot = true 
db_deletion_protection = false
db_performance_insights_enabled = false
db_apply_immediately = true
db_multi_az = false

#================= S3 =======================#

bucket_name = "tools-bucket-cloudranger-30293812"

