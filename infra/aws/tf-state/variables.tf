variable "region" {
  type        = string
  description = "AWS region for cluster"
  default     = "eu-west-1"
}

variable "bucket_name" {
  type        = string
  description = "bucket"
}

variable "lockdb_name" {
  type        = string
  description = "bucket"
}