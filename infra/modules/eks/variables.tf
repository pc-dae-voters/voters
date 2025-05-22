variable "vpc_id" {
  type    = string
  description = "The ID of the VPC to create the EKS cluster in"
}

variable "public_subnet_ids" {
  type    = list(string)
  description = "List of IDs of public subnets for the EKS cluster"
}

variable "private_subnet_ids" {
  type    = list(string)
  description = "List of IDs of private subnets for the EKS cluster"
}

variable "cluster_name" {
  type    = string
  default = "voting-app-eks"
  description = "The name of the EKS cluster"
}

variable "desired_capacity" {
  type    = number
  default = 2
  description = "The desired number of worker nodes in the EKS cluster"
}

variable "max_capacity" {
  type    = number
  default = 5
  description = "The maximum number of worker nodes in the EKS cluster"
}

variable "min_capacity" {
  type    = number
  default = 1
  description = "The minimum number of worker nodes in the EKS cluster"
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
  description = "The EC2 instance type for the worker nodes"
}

variable "tags" {
  type    = map(string)
  default = {}
  description = "Additional tags to apply to resources"
}
