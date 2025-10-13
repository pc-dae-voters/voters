output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}

output "tags" {
  description = "Tags applied to the resource group"
  value       = azurerm_resource_group.main.tags
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

# --- Manager VM ---
output "manager_vm_public_ip" {
  description = "Public IP address of the manager VM"
  value       = module.mgr_vm.public_ip_address
}

output "manager_vm_private_ssh_key" {
  description = "Private SSH key for the manager VM"
  value       = module.mgr_vm.private_ssh_key
  sensitive   = true
}

# --- AKS ---
output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = module.aks.cluster_name
}

output "aks_kube_config_raw" {
  description = "Raw Kubernetes configuration for the AKS cluster"
  value       = module.aks.kube_config_raw
  sensitive   = true
} 