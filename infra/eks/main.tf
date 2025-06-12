provider "aws" {
  region = "eu-west-1"
  default_tags {
    tags = {
      email = "paul.carlton@dae.mn"
    }
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "paulcarlton-voters-tfstate"
    key    = "vpc/terraform.tfstate"
    region = "eu-west-1"
  }
}

module "eks_cluster" {
  source = "../modules/eks"

  cluster_name       = "voters-cluster"
  vpc_id             = data.terraform_remote_state.vpc.outputs.vpc_id
  public_subnet_ids  = data.terraform_remote_state.vpc.outputs.public_subnet_ids
  private_subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnet_ids
  tags = {
    Project   = "Voters"
    ManagedBy = "Terraform"
  }
} 