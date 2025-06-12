provider "aws" {
  region = var.region
  default_tags {
    tags = {
      email = "paul.carlton@dae.mn"
    }
  }
}

module "vpc" {
  source = "../modules/vpc"

  vpc_cidr_block = var.vpc_cidr_block
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones = var.availability_zones
  tags = var.tags
} 