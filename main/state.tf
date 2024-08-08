terraform {
  backend "s3" {
    region = "us-east-1"
    bucket = "common-tf-state-legion-1" #need to change to globally unique value
    key    = "terraform.tfstate"
  }
}