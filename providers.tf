terraform {
  required_version = ">=0.12"

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~>1.5"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }

    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }
}


provider "azurerm" {
  features {}
  tenant_id = "5d0aa6ea-6620-4863-9e21-9ecb140222bc"
  # subscription_id = "08ed13bd-3f0a-40ff-8bd4-0396f1c10a0b" 
}
