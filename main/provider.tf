#terraform and providers versions
terraform {
  required_version = "~> 1.5.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.38.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.12.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.26.0"
    }  
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}



# Configure the AWS Provider
provider "aws" {
  region = "us-east-2"
  default_tags {
    tags = {
      Project     = "Devops Legion"
      Managed     = "By Terraform"
      Owner       = "DevOps Team"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  alias  = "east1"
  default_tags {
    tags = {
      Project     = "Devops Legion"
      Managed     = "By Terraform"
      Owner       = "DevOps Team"
    }
  }
}
