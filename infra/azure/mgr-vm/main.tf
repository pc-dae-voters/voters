terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# --- Network ---
resource "azurerm_public_ip" "manager" {
  name                = "${var.vm_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_network_interface" "manager" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.manager.id
  }
}

# --- VM ---
resource "azurerm_linux_virtual_machine" "manager" {
  name                            = var.vm_name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.manager.id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.manager_key.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(templatefile("${path.module}/cloud-init.sh", {
    db_host           = var.db_host
    db_name           = var.db_name
    db_username       = var.db_username
    db_password       = var.db_password
    version           = var.cloud_init_version
    terraform_version = var.terraform_version
  }))

  tags = var.tags
}

# --- Data Disk Attachment ---
resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  managed_disk_id    = var.data_disk_id
  virtual_machine_id = azurerm_linux_virtual_machine.manager.id
  lun                = 10
  caching            = "ReadWrite"
}

# --- SSH Key ---
resource "tls_private_key" "manager_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# --- Cloud-init ---
# The data "template_file" resource has been replaced by the built-in
# templatefile() function directly in the azurerm_linux_virtual_machine resource.
