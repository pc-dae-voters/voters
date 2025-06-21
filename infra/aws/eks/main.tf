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
    bucket = "dae-voters-tfstate"
    key    = "vpc/terraform.tfstate"
    region = "eu-west-1"
  }
}

module "eks_cluster" {
  source = "../modules/eks"

  cluster_name = "voters-cluster"
  subnet_ids   = data.terraform_remote_state.vpc.outputs.private_subnet_ids
  tags = {
    Project   = "Voters"
    ManagedBy = "Terraform"
  }
} 