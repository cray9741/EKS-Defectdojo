terraform {
  backend "s3" {
    region = "us-east-2"
    bucket = "common-tf-state-legion-2" #need to change to globally unique value
    key    = "terraform.tfstate"
  }
}