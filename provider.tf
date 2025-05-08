# Configure the Azure provider, you can have many
# if you use azurerm provider, it's source is hashicorp/azurerm
# short for registry.terraform.io/hashicorp/azurerm
 
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.12.0"
    }
  }
 
  required_version = ">= 1.9.0"
}
# configures the provider
 
provider "azurerm" {
  features {
    resource_group{
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = "db0613ba-f868-4402-a754-872985fd641b"
}