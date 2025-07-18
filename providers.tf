provider "azurerm" {
  tenant_id       = var.tenant_id
  subscription_id = var.sub_id
  client_id       = var.sp_id
  client_secret   = var.sp_secret
  features {

  }
}

terraform {
  backend "azurerm" {
    resource_group_name  = "sb-tfstate-sa"
    storage_account_name = "sbtfstateremote"
    container_name       = "statefilecon"
    key                  = "project2-terraform.tfstate"
  }
}