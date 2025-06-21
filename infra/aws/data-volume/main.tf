terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      email = "paul.carlton@dae.mn"
    }
  }
}

# EBS volume for persistent data
resource "aws_ebs_volume" "data" {
  availability_zone = var.availability_zone
  size              = var.size
  type              = var.volume_type
  tags = {
    Name = var.name
  }
} 