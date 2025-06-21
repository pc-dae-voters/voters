terraform {
  backend "s3" {
    bucket = "dae-voters-tfstate"
    key    = "data-loader/terraform.tfstate"
    region = "eu-west-1"
  }
} 