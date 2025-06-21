output "server_name" {
  description = "Name of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.name
}

output "db_name" {
  description = "Name of the PostgreSQL database"
  value       = azurerm_postgresql_flexible_server_database.main.name
}

output "connection_string" {
  description = "Connection string for the PostgreSQL database"
  value       = "postgresql://${var.admin_username}@${azurerm_postgresql_flexible_server.main.name}.postgres.database.azure.com:5432/${var.db_name}?sslmode=require"
  sensitive   = true
}

output "private_dns_zone_id" {
  description = "ID of the private DNS zone"
  value       = azurerm_private_dns_zone.main.id
} 