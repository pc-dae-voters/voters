resource "azurerm_postgresql_flexible_server" "main" {
  name                   = var.server_name
  resource_group_name    = var.resource_group_name
  location               = var.location
  version                = "14"
  delegated_subnet_id    = var.subnet_id
  private_dns_zone_id    = azurerm_private_dns_zone.main.id
  administrator_login    = var.admin_username
  administrator_password = random_password.db_password.result
  zone                   = "1"
  storage_mb             = 32768
  public_network_access_enabled = false

  sku_name = "B_Standard_B1ms"

  tags = var.tags
}

resource "azurerm_private_dns_zone" "main" {
  name                = "voters-private.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "main" {
  name                  = "${var.server_name}-link"
  private_dns_zone_name = azurerm_private_dns_zone.main.name
  resource_group_name   = var.resource_group_name
  virtual_network_id    = var.vnet_id
  tags                  = var.tags
}

resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = var.db_name
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

resource "random_password" "db_password" {
  length  = 16
  special = true
}

resource "azurerm_key_vault_secret" "db_password" {
  name         = "${var.server_name}-password"
  value        = random_password.db_password.result
  key_vault_id = var.key_vault_id
} 