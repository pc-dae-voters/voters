terraform {
  backend "s3" {
    bucket = "dae-voters-tfstate"
    key    = "data-volume/terraform.tfstate"
    region = "eu-west-1"
  }
} 