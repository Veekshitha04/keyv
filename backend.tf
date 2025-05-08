terraform {
  backend "azurerm" {
    resource_group_name  = "backend-state-rg"  
    storage_account_name = "storage229"                      
    container_name       = "tfstate3"                       
    key                  = "dev.terraform.tfstate"        
  }
  }