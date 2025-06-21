variable "region" {
  description = "The AWS region."
  type        = string
  default     = "eu-west-1"
}

variable "db_name" {
  description = "The name for the RDS database."
  type        = string
  default     = "voters"
}

variable "db_username" {
  description = "The master username for the RDS database."
  type        = string
  default     = "voteradmin"
} 