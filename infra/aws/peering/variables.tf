# region, owner_email, eks_cluster_name and tf_state_bucket are set from the EKS cluster's tf-config ConfigMap, see
# infra/aws/flux

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

variable "eks_cluster_name" {
  description = "EKS cluster whose VPC the voters VPC is peered with"
  type        = string
}
