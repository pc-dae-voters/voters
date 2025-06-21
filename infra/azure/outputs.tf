output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = module.network.vnet_name
}

output "subnet_ids" {
  description = "Map of subnet names to their IDs"
  value       = module.network.subnet_ids
}

output "db_server_name" {
  description = "Name of the PostgreSQL server"
  value       = module.database.server_name
}

output "db_name" {
  description = "Name of the PostgreSQL database"
  value       = module.database.db_name
}

output "db_connection_string" {
  description = "Connection string for the PostgreSQL database"
  value       = module.database.connection_string
  sensitive   = true
} 