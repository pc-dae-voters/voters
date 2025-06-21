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
    bucket = "dae-voters-tfstate"
    key    = "vpc/terraform.tfstate"
    region = var.region
  }
}

# Create a security group for the database that allows access from within the VPC
resource "aws_security_group" "database" {
  name_prefix = "voters-db-"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Allow PostgreSQL access from within VPC"
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

  db_name           = var.db_name
  subnet_ids        = data.terraform_remote_state.vpc.outputs.private_subnet_ids
  db_username       = var.db_username
  vpc_security_group_ids = [aws_security_group.database.id]
  publicly_accessible    = false
  tags = {
    Project = "Voters"
    ManagedBy = "Terraform"
  }
}