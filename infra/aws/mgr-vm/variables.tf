variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance (Amazon Linux 2023)"
  type        = string
  default     = "ami-0a0c8eebcdd6dcbd0" # Amazon Linux 2023 in eu-west-1
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
  description = "Git URL for the voters project"
  type        = string
  default     = "https://github.com/pc-dae-voters.git"
}

variable "additional_ssh_cidrs" {
  description = "Additional CIDR blocks allowed SSH access to the manager instance"
  type        = list(string)
  default     = []
}

variable "cloud_init_version" {
  description = "Version number for cloud-init configuration. Increment this to force cloud-init to run again."
  type        = string
  default     = "1.0"
} 