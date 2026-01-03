data "azurerm_resource_group" "main" {
  name = "eCommerce"
}
data "azurerm_subnet" "main" {
  name                 = "default"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = "vNET-eCommerce"
}