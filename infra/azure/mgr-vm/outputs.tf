output "public_ip_address" {
  description = "The public IP address of the manager VM"
  value       = azurerm_public_ip.manager.ip_address
}

output "private_ssh_key" {
  description = "The private SSH key for the manager VM"
  value       = tls_private_key.manager_key.private_key_pem
  sensitive   = true
}
