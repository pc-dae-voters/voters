terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  backend "azurerm" {
    # These values will be set by the backend configuration
    # resource_group_name  = "pc-dae-voters-tfstate"
    # storage_account_name = "pcdaevoterstfstate"
    # container_name      = "tfstate"
    # key                 = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Virtual Network
module "network" {
  source = "./modules/network"

  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  vnet_name          = var.vnet_name
  address_space      = var.vnet_address_space
  subnet_prefixes    = var.subnet_prefixes
  subnet_names       = var.subnet_names
  tags               = var.tags
}

# Database
module "database" {
  source = "./modules/database"

  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  server_name        = var.db_server_name
  db_name            = var.db_name
  admin_username     = var.db_admin_username
  subnet_id          = module.network.subnet_ids["db"]
  vnet_id            = module.network.vnet_id
  key_vault_id       = var.key_vault_id
  tags               = var.tags
} 