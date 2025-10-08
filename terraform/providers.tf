terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Provider Azure avec authentification automatique
provider "azurerm" {
  features {}

  # Terraform utilisera automatiquement la session az login
  # Aucune configuration d'authentification nécessaire
}
