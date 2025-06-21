terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
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

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "dae-voters-tfstate"
    key    = "vpc/terraform.tfstate"
    region = var.region
  }
}

data "terraform_remote_state" "db" {
  backend = "s3"
  config = {
    bucket = "dae-voters-tfstate"
    key    = "db/terraform.tfstate"
    region = var.region
  }
}

# SSH key pair for the data loader instance
resource "tls_private_key" "data_loader_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "data_loader_key_pair" {
  key_name   = "voters-data-loader-key"
  public_key = tls_private_key.data_loader_key.public_key_openssh
}

# Get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Get current user's public IP for SSH access
data "http" "my_ip" {
  url = "https://ipv4.icanhazip.com"
}

# Security group for the data loader instance
resource "aws_security_group" "data_loader" {
  name_prefix = "voters-data-loader-"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  # SSH access from your IP only
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.my_ip.response_body)}/32"]
    description = "SSH access from user IP"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "voters-data-loader-sg"
  }
}

# IAM role for the EC2 instance
resource "aws_iam_role" "data_loader_role" {
  name = "voters-data-loader-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAM instance profile
resource "aws_iam_instance_profile" "data_loader_profile" {
  name = "voters-data-loader-profile"
  role = aws_iam_role.data_loader_role.name
}

# Cloud-init configuration
data "cloudinit_config" "data_loader" {
  gzip          = false
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = templatefile("${path.module}/cloud-init.sh", {
      db_host     = data.terraform_remote_state.db.outputs.db_instance_endpoint
      db_name     = data.terraform_remote_state.db.outputs.db_name
      db_username = data.terraform_remote_state.db.outputs.db_username
      db_password = data.terraform_remote_state.db.outputs.db_password
      timestamp   = timestamp()
    })
  }
}

# EC2 instance
resource "aws_instance" "data_loader" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = data.terraform_remote_state.vpc.outputs.public_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.data_loader.id]
  key_name               = aws_key_pair.data_loader_key_pair.key_name
  user_data_base64       = data.cloudinit_config.data_loader.rendered

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
  }

  tags = {
    Name = "voters-data-loader"
  }
} 