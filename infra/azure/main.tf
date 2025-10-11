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

data "azurerm_client_config" "current" {}

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
  key_vault_id       = module.key_vault.key_vault_id
  tags               = var.tags
}

# Key Vault
module "key_vault" {
  source = "./modules/key-vault"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  key_vault_name      = var.key_vault_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  spn_object_id       = data.azurerm_client_config.current.object_id
  tags                = var.tags
}

# Data Volume
module "data_volume" {
  source = "./data-volume"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  disk_name           = var.disk_name
  disk_size_gb        = var.disk_size_gb
  tags                = var.tags
}

# Manager VM
module "mgr_vm" {
  source = "./mgr-vm"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  subnet_id           = module.network.subnet_ids["app"]
  data_disk_id        = module.data_volume.disk_id
  vm_name             = var.vm_name
  vm_size             = var.vm_size
  admin_username      = var.admin_username
  db_host             = module.database.server_name
  db_name             = module.database.db_name
  db_username         = var.db_admin_username
  db_password         = module.database.admin_password
  tags                = var.tags
}

# AKS Cluster
module "aks" {
  source = "./aks"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  cluster_name        = var.cluster_name
  kubernetes_version  = var.kubernetes_version
  node_count          = var.node_count
  vm_size             = var.vm_size
  subnet_id           = module.network.subnet_ids["app"]
  tags                = var.tags
} 