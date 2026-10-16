# region, owner_email and tf_state_bucket are set from the EKS cluster's tf-config ConfigMap, see infra/aws/flux

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

variable "size" {
  description = "Size of the EBS volume in GB"
  type        = number
  default     = 20
}

variable "volume_type" {
  description = "Type of EBS volume"
  type        = string
  default     = "gp3"
}

variable "name" {
  description = "Name tag for the EBS volume"
  type        = string
  default     = "voters-data-loader-data"
}
