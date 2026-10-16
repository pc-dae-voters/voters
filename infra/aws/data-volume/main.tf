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

# EBS volume for the data uploaded by bin/upload-data.sh, mounted at /data on the manager VM, which runs in the first
# public subnet's availability zone. It is kept when the VM is replaced
resource "aws_ebs_volume" "data" {
  availability_zone = data.terraform_remote_state.vpc.outputs.availability_zones[0]
  size              = var.size
  type              = var.volume_type
  tags = {
    Name = var.name
  }
}
