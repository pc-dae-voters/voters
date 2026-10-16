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

data "terraform_remote_state" "db" {
  backend = "s3"
  config = {
    bucket = var.tf_state_bucket
    key    = "voters-infra/db/terraform.tfstate"
    region = var.region
  }
}

data "terraform_remote_state" "data_volume" {
  backend = "s3"
  config = {
    bucket = var.tf_state_bucket
    key    = "voters-infra/data-volume/terraform.tfstate"
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

# Security group for the manager instance
resource "aws_security_group" "manager" {
  name_prefix = "voters-manager-"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  # SSH access, bin/upload-data.sh and bin/mgr-ssh.sh
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [for c in split(",", var.ssh_cidrs) : trimspace(c)]
    description = "SSH access from ssh_cidrs"
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

# Cloud-init configuration
data "cloudinit_config" "manager" {
  gzip          = false
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = templatefile("${path.module}/cloud-init.sh", {
      db_host     = data.terraform_remote_state.db.outputs.db_host
      db_name     = data.terraform_remote_state.db.outputs.db_name
      db_username = data.terraform_remote_state.db.outputs.db_username
      db_password = data.terraform_remote_state.db.outputs.db_password
      git_url     = var.project_git_url
      git_branch  = var.project_git_branch
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

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
  }

  tags = {
    Name = "voters-manager"
  }
}

# Attach the data volume to the instance
resource "aws_volume_attachment" "data" {
  device_name = "/dev/xvdf"
  volume_id   = data.terraform_remote_state.data_volume.outputs.volume_id
  instance_id = aws_instance.manager.id
  force_detach = true
} 