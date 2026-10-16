# region, owner_email, tf_state_bucket and ssh_cidrs are set from the EKS cluster's tf-config ConfigMap, the git
# settings from the voters-infra Terraform object, see infra/aws/flux

variable "region" {
  description = "AWS region"
  type        = string
}

variable "owner_email" {
  description = "Email address added to the resources' tags"
  type        = string
  default     = ""
}

variable "tf_state_bucket" {
  description = "S3 bucket holding the voters modules' state, read using terraform_remote_state"
  type        = string
}

variable "ssh_cidrs" {
  description = "Comma separated CIDR blocks allowed SSH access to the manager instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 50
}

variable "project_git_url" {
  description = "Git URL of the voters project, cloned to /home/ec2-user/pc-dae-voters"
  type        = string
  default     = "https://github.com/pc-dae-voters/voters.git"
}

variable "project_git_branch" {
  description = "Branch of the voters project to clone"
  type        = string
  default     = "main"
}

variable "cloud_init_version" {
  description = "Version number for cloud-init configuration. Increment this to force cloud-init to run again, it replaces the instance."
  type        = string
  default     = "1.0"
}
