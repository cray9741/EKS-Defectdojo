resource "aws_security_group" "vpn_sg" {
  name        = "${var.env}-vpn-sg"
  description = "Allow to connect VPN host"
  vpc_id      = module.vpc.vpc_id
  ingress {
    description = "SSH whitelisted IPs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }
  ingress {
    description = "All from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }
  ingress {
    description = "All from VPC"
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }    
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "build_agent_sg" {
  name        = "${var.env}-build-agent-sg"
  description = "Allow to connect VPN host"
  vpc_id      = module.vpc.vpc_id
  ingress {
    description = "All from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }   
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#SG for DB
resource "aws_security_group" "mysqldb_sg" {
  name        = "${var.env}-db-sg"
  description = "Allow from VPC"
  vpc_id      = module.vpc.vpc_id
  ingress {
    description = "MYSQL DB Port"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  ingress {
    description = "MYSQL DB Port for PRD VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.235.0.0/16"]
  }    
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}