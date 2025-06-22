terraform {
  backend "s3" {
    bucket         = "dae-voters-tfstate"
    key            = "db/terraform.tfstate"
    region         = "eu-west-1"
  }
} 