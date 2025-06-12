terraform {
  backend "s3" {
    bucket         = "paulcarlton-voters-tfstate"
    key            = "eks/terraform.tfstate"
    region         = "eu-west-1"
    use_lockfile   = true
  }
} 