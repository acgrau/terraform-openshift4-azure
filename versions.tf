
terraform {
  required_version = ">= 0.13"
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.14.0"
    }
    local = {
      source = "hashicorp/local"
    }
    random = {
      source = "hashicorp/random"
    }
    tls = {
      source = "hashicorp/tls"
    }
    template = {
      source = "hashicorp/template"
    }
    infoblox = {
      source = "infobloxopen/infoblox"
      version = "2.1.0"
    }
  }
}
