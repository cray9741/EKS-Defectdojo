#Enviroment variables general
variable "region" {
  description = "AWS Region"
  type        = string
}

variable "env" {
  description = "ENV name"
  type        = string
}

#============= VPC ==============#
variable "vpc_name" {
  type        = string
  description = "VPC name"
}

variable "vpc_version" {
  type        = string
  description = "VPC module version"
}

variable "vpc_cidr" {
  type        = string
  description = "cidr block"
}

variable "az_list" {
  type        = list(string)
  description = "List of Availability Zones"
}

variable "public_subnets" {
  type        = list(string)
  description = "List of Public Subnets"
}

variable "private_subnets" {
  type        = list(string)
  description = "List of Private Subnets"
}

variable "db_subnets" {
  type        = list(string)
  description = "List of DB Subnets"
}

variable "enable_nat_gateway" {
  type        = string
  description = "Should be true if you want to provision NAT Gateways for each of your private networks"
}

variable "enable_dns_hostnames" {
  type        = string
  description = "Should be true to enable DNS hostnames in the VPC"
}

variable "enable_dns_support" {
  type        = string
  description = "Should be true to enable DNS support in the VPC"
}

#=============== EKS =================#
variable "eks_cluster_name" {
  type        = string
  description = "EKS Cluster name"
}

variable "eks_cluster_version" {
  type        = string
  description = "EKS Cluster version"
}

variable "eks_cluster_instance_type" {
  type        = string
  description = "EKS Cluster instance type"
}

variable "eks_cluster_log_types" {
  type        = list(string)
  description = "EKS Cluster log types"
}

variable "eks_cluster_min_size" {
  type        = string
  description = "The minimum number of nodes that the managed node group can scale in to"
}

variable "eks_cluster_max_size" {
  type        = string
  description = "The maximum number of nodes that the managed node group can scale out to"
}

variable "eks_cluster_des_size" {
  type        = string
  description = "The current number of nodes that the managed node group should maintain"
}

variable "eks_cluster_ami_type" {
  type        = string
  description = "AMI type that was specified in the node group configuration"
}

variable "eks_cluster_capacity" {
  type        = string
  description = "The capacity type of your managed node group [ON_DEMAND | SPOT]"
}

variable "eks_max_unavailable_percentage" {
  type        = string
  description = "The maximum number of nodes unavailable at once during a version update"
}

variable "eks_map_roles" {
  description = "Additional IAM roles to add to `config-map-aws-auth` ConfigMap"
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
}

variable "eks_map_users" {
  description = "Additional IAM users to add to `config-map-aws-auth` ConfigMap"
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
}

variable "sc_list" {
  type        = list(string)
  description = "List of sc names"
}

#=============== WAF =================#
variable "allowed_cidr_blocks" {
  type        = list(any)
  description = "List of allowed IPs"
}


#================= AWS KMS =======================#
variable "kms_deletion_window_in_days" {
  type        = string
  description = "KMS key for EKS secrets - deletion period"    
}

#================= RDS =======================#

variable "db_identifier" {
  type        = string
  description = "DB identifier"    
}

variable "db_engine_version" {
  type        = string
  description = "DB engine version"    
}


variable "db_engine" {
  type        = string
  description = "DB engine"    
}


variable "db_family" {
  type        = string
  description = "DB family"    
}

variable "db_major_engine_version" {
  type        = string
  description = "DB major engine version"    
}

variable "db_instance_class" {
  type        = string
  description = "DB instance class"    
}

variable "db_name" {
  type        = string
  description = "DB name"    
}

variable "db_port" {
  type        = string
  description = "DB port"    
}

variable "db_allocated_storage" {
  type        = string
  description = "DB allocated storage in gigabytes"    
}

variable "db_max_allocated_storage" {
  type        = string
  description = "DB max allocated storage in gigabytes"    
}

variable "db_storage_encrypted" {
  type        = string
  description = "Specifies whether the DB instance is encrypted"    
}

variable "db_maintenance_window" {
  type        = string
  description = "Specifies DB maintenance window"    
}

variable "db_backup_window" {
  type        = string
  description = "Specifies DB backup window"    
}

variable "db_backup_retention_period" {
  type        = string
  description = "Specifies DB retention period"    
}

variable "db_skip_final_snapshot" {
  type        = string
  description = "Determines whether a final DB snapshot is created before the DB instance is deleted."    
}

variable "db_deletion_protection" {
  type        = string
  description = "The database can't be deleted when this value is set to true"    
}

variable "db_performance_insights_enabled" {
  type        = string
  description = "Specifies whether Performance Insights are enabled"    
}

variable "db_apply_immediately" {
  type        = string
  description = "Specifies whether any database modifications are applied immediately, or during the next maintenance window"    
}

variable "db_multi_az" {
  type        = string
  description = "Specifies if the RDS instance is multi-AZ"    
}

#=============== S3 =================#

variable "bucket_name" {
  type        = string
  description = "THe Bucekt name"    
}
