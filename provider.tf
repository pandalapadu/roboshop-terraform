terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.49"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "5.3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.3"
    }
  }
}
provider "azurerm" {
  features {}
  subscription_id = "af504235-2f6d-4469-aa25-251f498730fc"
}
terraform {
  backend "azurerm" { }
}

provider "vault" {
  address = "http://vault-internal.azdevopsvenkat.site:8200"
  token   = var.token
}

