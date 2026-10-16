data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  tags = merge({
    Project   = "voters"
    ManagedBy = "tofu-controller"
  }, var.owner_email == "" ? {} : { email = var.owner_email })
}

# Public subnets for the manager VM, private subnets for the database. There is no NAT gateway, the database doesn't
# need internet access
module "vpc" {
  source = "../modules/vpc"

  vpc_cidr_block       = var.vpc_cidr_block
  public_subnet_cidrs  = [for i, az in local.azs : cidrsubnet(var.vpc_cidr_block, 8, i)]
  private_subnet_cidrs = [for i, az in local.azs : cidrsubnet(var.vpc_cidr_block, 8, i + 100)]
  availability_zones   = local.azs
  enable_nat_gateway   = false
}
