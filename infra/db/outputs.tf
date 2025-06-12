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