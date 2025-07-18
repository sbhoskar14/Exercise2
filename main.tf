resource "azurerm_resource_group" "az_rg" {
  name     = var.rg_names
  location = var.rg_loc
}

resource "azurerm_virtual_network" "az_vnet" {
  name                = var.vnet_name
  resource_group_name = azurerm_resource_group.az_rg.name
  location            = azurerm_resource_group.az_rg.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "az_subnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_virtual_network.az_vnet.resource_group_name
  virtual_network_name = azurerm_virtual_network.az_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}


resource "azurerm_public_ip" "az_public_ip" {
  name                = var.public_ip_name
  resource_group_name = azurerm_resource_group.az_rg.name
  location            = azurerm_resource_group.az_rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "nic1" {
  name                = var.nic_name
  resource_group_name = azurerm_resource_group.az_rg.name
  location            = azurerm_resource_group.az_rg.location
  ip_configuration {
    name                          = "testinternal"
    subnet_id                     = azurerm_subnet.az_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.az_public_ip.id
  }
}

data "azurerm_key_vault" "az_kv" {
  name                = "sbkeystore"
  resource_group_name = "RG-keyvault"
}

data "azurerm_key_vault_secret" "az_kv_sec" {
  name         = "vm-pass"
  key_vault_id = data.azurerm_key_vault.az_kv.id
}

resource "azurerm_linux_virtual_machine" "az_vm" {
  name                            = var.vm_name
  location                        = azurerm_resource_group.az_rg.location
  resource_group_name             = azurerm_resource_group.az_rg.name
  network_interface_ids           = [azurerm_network_interface.nic1.id]
  size                            = "Standard_DS1_v2"
  admin_username                  = "azureuser"
  admin_password                  = data.azurerm_key_vault_secret.az_kv_sec.value
  disable_password_authentication = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "webapp-osdisk"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y apache2",
      "echo '<h1>Welcome to Apache on Azure</h1>' | sudo tee /var/www/html/index.html",
      "sudo systemctl restart apache2"
    ]

    connection {
      type     = "ssh"
      user     = "azureuser"
      password = data.azurerm_key_vault_secret.az_kv_sec.value
      host     = azurerm_linux_virtual_machine.az_vm.public_ip_address
    }
  }
}

resource "azurerm_image" "az_vm_image" {
  name                      = "webapp-image"
  location                  = azurerm_resource_group.az_rg.location
  resource_group_name       = azurerm_resource_group.az_rg.name
  source_virtual_machine_id = azurerm_linux_virtual_machine.az_vm.id
}