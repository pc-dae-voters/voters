variable "db_name" {
  description = "The name of the database"
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "instance_class" {
  description = "The instance class for the RDS database"
  type        = string
  default     = "db.t3.micro"
}

variable "engine_version" {
  description = "The version of the PostgreSQL engine"
  type        = string
  default     = "15.7"
}

variable "db_username" {
  description = "The master username for the database"
  type        = string
}

variable "vpc_security_group_ids" {
  description = "A list of VPC security group IDs to associate with the database"
  type        = list(string)
  default     = []
}

variable "publicly_accessible" {
  description = "Whether the database should be publicly accessible"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default     = {}
}