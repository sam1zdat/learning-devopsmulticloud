variable "project_name" {
  description = "Nom de votre projet"
  type        = string
  default     = "myapp"
}

variable "environment" {
  description = "Environnement de déploiement"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Région Azure"
  type        = string
  default     = "francecentral"
}

variable "app_service_sku" {
  description = "SKU App Service"
  type        = string
  default     = "F1"
}

# 🔥 NOUVEAU: Nom du Resource Group existant
variable "existing_resource_group_name" {
  description = "Nom du Resource Group existant"
  type        = string
}

variable "existing_resource_group_location" {
  description = "Localisation du Resource Group existant"
  type        = string
  default     = "francecentral"
}