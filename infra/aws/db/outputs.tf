output "db_instance_endpoint" {
  description = "The connection endpoint for the database instance."
  value       = module.database.db_instance_endpoint
}

output "db_name" {
  description = "The name of the database."
  value       = module.database.db_instance_name
}

output "db_username" {
  description = "The master username for the database."
  value       = var.db_username
}

output "db_password" {
  description = "The password for the master user."
  value       = module.database.db_password
  sensitive   = true
}

output "db_security_group_id" {
  description = "The ID of the security group for the database."
  value       = aws_security_group.database.id
}

output "vpc_id" {
  description = "The ID of the VPC where the database is located."
  value       = data.terraform_remote_state.vpc.outputs.vpc_id
} 