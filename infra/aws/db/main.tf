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

data "http" "my_ip" {
  url = "https://ipv4.icanhazip.com"
}

resource "aws_security_group_rule" "allow_my_ip" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = ["${chomp(data.http.my_ip.response_body)}/32"]
  security_group_id = data.terraform_remote_state.vpc.outputs.default_security_group_id
  description       = "Allow inbound traffic from my IP"
}

module "database" {
  source = "../modules/rds"

  db_name      = var.db_name
  subnet_ids   = data.terraform_remote_state.vpc.outputs.public_subnet_ids
  db_username  = var.db_username
  tags = {
    Project = "Voters"
    ManagedBy = "Terraform"
  }
}