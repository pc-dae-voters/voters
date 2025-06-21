terraform {
  backend "s3" {
    bucket         = "dae-voters-tfstate"
    key            = "eks/terraform.tfstate"
    region         = "eu-west-1"
    use_lockfile   = true
  }
} 