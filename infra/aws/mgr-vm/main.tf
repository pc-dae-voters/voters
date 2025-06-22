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

data "terraform_remote_state" "data_volume" {
  backend = "s3"
  config = {
    bucket = "dae-voters-tfstate"
    key    = "data-volume/terraform.tfstate"
    region = var.region
  }
}

# SSH key pair for the manager instance
# Generate a new private key
resource "tls_private_key" "manager_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Register the public key with AWS
resource "aws_key_pair" "manager_key_pair" {
  key_name   = "voters-manager-key"
  public_key = tls_private_key.manager_key.public_key_openssh
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

# Security group for the manager instance
resource "aws_security_group" "manager" {
  name_prefix = "voters-manager-"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  # SSH access from your IP and additional CIDRs
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = concat(["${chomp(data.http.my_ip.response_body)}/32"], var.additional_ssh_cidrs)
    description = "SSH access from user IP and additional CIDRs"
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
    Name = "voters-manager-sg"
  }
}

# IAM admin role for the EC2 instance with Administrator privileges
resource "aws_iam_role" "manager_admin_role" {
  name = "voters-manager-admin-role"

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

# Attach Administrator policy to the admin role
resource "aws_iam_role_policy_attachment" "manager_admin_policy" {
  role       = aws_iam_role.manager_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# IAM instance profile
resource "aws_iam_instance_profile" "manager_profile" {
  name = "voters-manager-admin-profile"
  role = aws_iam_role.manager_admin_role.name
}

# Cloud-init configuration
data "cloudinit_config" "manager" {
  gzip          = false
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = templatefile("${path.module}/cloud-init.sh", {
      db_host     = replace(data.terraform_remote_state.db.outputs.db_instance_endpoint, ":5432", "")
      db_name     = data.terraform_remote_state.db.outputs.db_name
      db_username = data.terraform_remote_state.db.outputs.db_username
      db_password = data.terraform_remote_state.db.outputs.db_password
      version     = var.cloud_init_version
    })
  }
}

# EC2 instance
resource "aws_instance" "manager" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = data.terraform_remote_state.vpc.outputs.public_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.manager.id]
  key_name               = aws_key_pair.manager_key_pair.key_name
  user_data_base64       = data.cloudinit_config.manager.rendered
  iam_instance_profile   = aws_iam_instance_profile.manager_profile.name

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
  }

  tags = {
    Name = "voters-manager"
    email = "paul.carlton@dae.mn"
  }
}

# Attach the data volume to the instance
resource "aws_volume_attachment" "data" {
  device_name = "/dev/xvdf"
  volume_id   = data.terraform_remote_state.data_volume.outputs.volume_id
  instance_id = aws_instance.manager.id
  force_detach = true
} 