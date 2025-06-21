variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "availability_zone" {
  description = "Availability zone for the EBS volume"
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