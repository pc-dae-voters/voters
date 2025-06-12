provider "aws" {
  region = var.region
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
    region = var.region
  }
}

module "database" {
  source = "../modules/rds"

  db_name      = var.db_name
  subnet_ids   = data.terraform_remote_state.vpc.outputs.private_subnet_ids
  db_username  = var.db_username
  tags = {
    Project = "Voters"
    ManagedBy = "Terraform"
  }
}