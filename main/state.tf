terraform {
  backend "s3" {
    region = "us-east-1"
    bucket = "test-backend-92813" #need to change to globally unique value
    key    = "terraform.tfstate"
  }
}