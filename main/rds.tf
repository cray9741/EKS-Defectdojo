resource "aws_kms_key" "rds" {
  description             = "KMS key for ${var.env} DBs"
  deletion_window_in_days = var.kms_deletion_window_in_days
}

#Setup dev DB
module "dev-db" {
  count   = var.env == "nonprod" ? 1 : 0
  source  = "terraform-aws-modules/rds/aws"
  # souce  = "../rds/"
  version = "6.4.0"
  identifier = var.db_identifier
  engine               = var.db_engine
  engine_version       = var.db_engine_version
  family               = var.db_family
  major_engine_version = var.db_major_engine_version      
  instance_class       = var.db_instance_class

  db_name  = var.db_name
  
  # change to parameter store
  
  #username = jsondecode(data.aws_secretsmanager_secret_version.g-secs.secret_string)["dev-db-user"]
  #password = jsondecode(data.aws_secretsmanager_secret_version.g-secs.secret_string)["dev-db-pass"]
  username = "testuser"
  password = "veryStrongPass_not"
  manage_master_user_password = false
  port     = var.db_port

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_encrypted = var.db_storage_encrypted
  kms_key_id = aws_kms_key.rds.arn
  
  maintenance_window = var.db_maintenance_window
  backup_window      = var.db_backup_window
  backup_retention_period = var.db_backup_retention_period
  skip_final_snapshot = var.db_skip_final_snapshot
  deletion_protection = var.db_deletion_protection
  performance_insights_enabled = var.db_performance_insights_enabled
  apply_immediately = var.db_apply_immediately
  multi_az               = var.db_multi_az
  ca_cert_identifier = "rds-ca-rsa2048-g1"

  parameters = [
    {
      name = "log_bin_trust_function_creators"
      value = "1"
    }
  ]    
    
  # DB subnet group
  create_db_subnet_group = true
  subnet_ids             = module.vpc.database_subnets
  vpc_security_group_ids = [aws_security_group.mysqldb_sg.id]
} 
