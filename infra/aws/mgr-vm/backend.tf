terraform {
  backend "s3" {
    bucket = "dae-voters-tfstate"
    key    = "mgr-vm/terraform.tfstate"
    region = "eu-west-1"
  }
} 