variable "vpc_id" {
  type    = string
  description = "The ID of the VPC to create the RDS instance in"
}

variable "private_subnet_ids" {
  type    = list(string)
  description = "List of IDs of private subnets for the RDS instance"
}

variable "db_name" {
  type    = string
  default = "voting_app_db"
  description = "The name of the database"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
  description = "The instance class for the RDS instance"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
  description = "The allocated storage (in GB) for the RDS instance"
}

variable "db_username" {
  type    = string
  default = "dbadmin"
  description = "The master username for the database"
  sensitive = true
}

variable "db_password" {
  type    = string
  description = "The master password for the database"
  sensitive = true
}

variable "tags" {
  type    = map(string)
  default = {}
  description = "Additional tags to apply to resources"
}
