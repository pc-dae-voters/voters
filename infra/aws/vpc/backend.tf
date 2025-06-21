terraform {
  backend "s3" {
    bucket         = "dae-voters-tfstate"
    key            = "vpc/terraform.tfstate"
    region         = "eu-west-1"
    use_lockfile   = true
  }
} 