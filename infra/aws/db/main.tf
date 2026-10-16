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

# Allows access from the voters VPC, i.e. the manager VM, and the peered EKS cluster's VPC, i.e. the voters app
resource "aws_security_group" "database" {
  name_prefix = "voters-db-"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.vpc.outputs.vpc_cidr_block, data.aws_vpc.eks.cidr_block]
    description = "PostgreSQL from the voters and EKS VPCs"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "voters-database-sg"
  }
}

module "database" {
  source = "../modules/rds"

  db_name                = var.db_name
  subnet_ids             = data.terraform_remote_state.vpc.outputs.private_subnet_ids
  db_username            = var.db_username
  vpc_security_group_ids = [aws_security_group.database.id]
  publicly_accessible    = false
}
