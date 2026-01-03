terraform {
  backend "azurerm" {
    resource_group_name = "eCommerce"
    storage_account_name = "azdevopsvenkat"
    container_name = "tfstates"
  }
}