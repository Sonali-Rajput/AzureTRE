data "azurerm_client_config" "deployer" {}

# See https://microsoft.github.io/AzureTRE/tre-developers/letsencrypt/
resource "azurerm_storage_account" "staticweb" {
  name                      = local.staticweb_storage_name
  resource_group_name       = local.core_resource_group_name
  location                  = var.location
  account_kind              = "StorageV2"
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  enable_https_traffic_only = true
  allow_blob_public_access  = true

  tags = {
    tre_id = var.tre_id
  }

  static_website {
    index_document     = "index.html"
    error_404_document = "404.html"
  }

  lifecycle { ignore_changes = [tags] }
}

# Assign the "Storage Blob Data Contributor" role needed for uploading certificates to the storage account
resource "azurerm_role_assignment" "stgwriter" {
  scope                = azurerm_storage_account.staticweb.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.deployer.object_id
}