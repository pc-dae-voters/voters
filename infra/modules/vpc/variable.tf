variable "vpc_cidr_block" {
  type    = string
  default = "10.0.0.0/16"
  description = "CIDR block for the VPC"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
  description = "List of CIDR blocks for public subnets"
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
  description = "List of CIDR blocks for private subnets"
}

variable "availability_zones" {
  type    = list(string)
  default = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  description = "List of Availability Zones to create subnets in"
}

variable "enable_nat_gateway" {
  type    = bool
  default = true
  description = "Whether to create a NAT Gateway for private subnets"
}

variable "single_nat_gateway" {
  type    = bool
  default = false
  description = "Whether to use a single NAT Gateway (less resilient, more cost-effective)"
}

variable "tags" {
  type    = map(string)
  default = {}
  description = "Additional tags to apply to resources"
}
