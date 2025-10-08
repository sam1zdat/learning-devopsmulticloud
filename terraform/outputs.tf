output "web_app_name" {
  description = "Nom de l'application web"
  value       = azurerm_linux_web_app.main.name
}

output "web_app_url" {
  description = "URL de l'application"
  value       = "https://${azurerm_linux_web_app.main.default_hostname}"
}

output "web_app_id" {
  description = "ID de l'application web"
  value       = azurerm_linux_web_app.main.id
}

output "service_plan_id" {
  description = "ID du App Service Plan"
  value       = azurerm_service_plan.main.id
}
