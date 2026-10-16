locals {
  tags = merge({
    Project   = "voters"
    ManagedBy = "tofu-controller"
  }, var.owner_email == "" ? {} : { email = var.owner_email })
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = var.tf_state_bucket
    key    = "voters-infra/vpc/terraform.tfstate"
    region = var.region
  }
}

data "aws_eks_cluster" "eks" {
  name = var.eks_cluster_name
}

data "aws_vpc" "eks" {
  id = data.aws_eks_cluster.eks.vpc_config[0].vpc_id
}

# The route tables associated with the EKS VPC's subnets. The main route table isn't used by them, and the EKS
# cluster's Terraform manages its routes, removing any others
data "aws_route_tables" "eks" {
  vpc_id = data.aws_vpc.eks.id
  filter {
    name   = "association.main"
    values = ["false"]
  }
}

# The VPCs are in the same account and region, so the peering connection is accepted when it is created
resource "aws_vpc_peering_connection" "eks" {
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  peer_vpc_id = data.aws_vpc.eks.id
  auto_accept = true

  tags = {
    Name = "voters-${var.eks_cluster_name}"
  }
}

# Private DNS names, e.g. the database's endpoint, resolve to private IP addresses in the peered VPC
resource "aws_vpc_peering_connection_options" "eks" {
  vpc_peering_connection_id = aws_vpc_peering_connection.eks.id

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_route" "voters_to_eks" {
  for_each = toset(data.terraform_remote_state.vpc.outputs.route_table_ids)

  route_table_id            = each.value
  destination_cidr_block    = data.aws_vpc.eks.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.eks.id
}

# The EKS VPC's route tables are managed by the EKS cluster's Terraform, these routes are separate resources so it
# doesn't remove them
resource "aws_route" "eks_to_voters" {
  for_each = toset(data.aws_route_tables.eks.ids)

  route_table_id            = each.value
  destination_cidr_block    = data.terraform_remote_state.vpc.outputs.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.eks.id
}
