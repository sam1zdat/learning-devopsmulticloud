# Data source pour récupérer le Resource Group existant
data "azurerm_resource_group" "existing" {
  name = var.existing_resource_group_name
}

# Plan App Service
resource "azurerm_service_plan" "main" {
  name                = "asp-${var.project_name}-${var.environment}"
  resource_group_name = data.azurerm_resource_group.existing.name
  location            = data.azurerm_resource_group.existing.location
  os_type             = "Linux"
  sku_name            = var.app_service_sku

  tags = {
    environment = var.environment
    project     = var.project_name
    deployedby  = "terraform"
  }
}

# Application Web
resource "azurerm_linux_web_app" "main" {
  name                = "app-${var.project_name}-${var.environment}-${random_string.suffix.result}"
  resource_group_name = data.azurerm_resource_group.existing.name
  location            = data.azurerm_resource_group.existing.location
  service_plan_id     = azurerm_service_plan.main.id

  site_config {
    application_stack {
      node_version = "18-lts"
    }
    always_on = false
  }

  app_settings = {
    "WEBSITE_NODE_DEFAULT_VERSION" = "18-lts"
    "NODE_ENV" = "production"
  }

  tags = {
    environment = var.environment
    project     = var.project_name
  }
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}
