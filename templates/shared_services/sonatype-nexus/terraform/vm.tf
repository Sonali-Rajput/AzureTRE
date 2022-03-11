resource "azurerm_network_interface" "internal" {
  name                = "internal-nic-nexus-${var.tre_id}"
  location            = var.location
  resource_group_name = local.core_resource_group_name

  ip_configuration {
    name                          = "primary"
    subnet_id                     = data.azurerm_subnet.shared.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "random_password" "password" {
  length           = 16
  lower            = true
  min_lower        = 1
  upper            = true
  min_upper        = 1
  number           = true
  min_numeric      = 1
  special          = true
  min_special      = 1
  override_special = "_%@"
}

resource "azurerm_key_vault_secret" "nexus_vm_password" {
  name         = "nexus-vm-password"
  value        = random_password.password.result
  key_vault_id = data.azurerm_key_vault.kv.id
}

resource "azurerm_linux_virtual_machine" "nexus" {
  name                            = "nexus-${var.tre_id}"
  resource_group_name             = local.core_resource_group_name
  location                        = var.location
  network_interface_ids           = [azurerm_network_interface.internal.id]
  size                            = "Standard_B2s"
  disable_password_authentication = false
  admin_username                  = "adminuser"
  admin_password                  = random_password.password.result

  custom_data = data.template_cloudinit_config.nexus_config.rendered

  lifecycle { ignore_changes = [tags] }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    name                 = "osdisk-nexus-${var.tre_id}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  identity {
    type = "SystemAssigned"
  }
}

data "template_cloudinit_config" "nexus_config" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = data.template_file.nexus_config.rendered
  }
}

data "template_file" "nexus_config" {
  template = file("${path.module}/cloud-config.yaml")
}