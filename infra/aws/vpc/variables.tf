# region and owner_email are set from the EKS cluster's tf-config ConfigMap, see infra/aws/flux

variable "region" {
  description = "AWS region"
  type        = string
}

variable "owner_email" {
  description = "Email address added to the resources' tags"
  type        = string
  default     = ""
}

# Must not overlap the EKS cluster's VPC, 10.0.0.0/16, which it is peered with
variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones, RDS needs subnets in at least two"
  type        = number
  default     = 2
}
