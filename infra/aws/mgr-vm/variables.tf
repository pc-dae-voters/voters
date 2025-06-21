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