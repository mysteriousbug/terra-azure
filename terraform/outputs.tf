# App Service Outputs
output "app_service_url" {
  description = "URL of the App Service"
  value       = "https://${module.compute.app_service_hostname}"
}

output "app_service_id" {
  description = "ID of the App Service"
  value       = module.compute.app_service_id
}

output "app_service_principal_id" {
  description = "Principal ID of the App Service managed identity"
  value       = module.compute.app_service_principal_id
}

# Database Outputs
output "database_fqdn" {
  description = "FQDN of the PostgreSQL server"
  value       = module.database.database_fqdn
  sensitive   = true
}

output "database_connection_string" {
  description = "Connection string for the database"
  value       = module.database.connection_string
  sensitive   = true
}

# Storage Outputs
output "storage_account_name" {
  description = "Name of the storage account"
  value       = module.storage.storage_account_name
}

output "storage_account_primary_endpoint" {
  description = "Primary endpoint of the storage account"
  value       = module.storage.primary_web_endpoint
}

output "storage_account_primary_key" {
  description = "Primary key of the storage account"
  value       = module.storage.primary_access_key
  sensitive   = true
}

# Networking Outputs
output "vnet_id" {
  description = "ID of the Virtual Network"
  value       = module.networking.vnet_id
}

output "application_gateway_public_ip" {
  description = "Public IP of the Application Gateway"
  value       = module.networking.application_gateway_public_ip
}

# Key Vault Outputs
output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = module.key_vault.key_vault_uri
}

output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = module.key_vault.key_vault_id
}

# Container Registry Outputs
output "container_registry_login_server" {
  description = "Login server of the Container Registry"
  value       = module.compute.container_registry_login_server
}

output "container_registry_admin_username" {
  description = "Admin username of the Container Registry"
  value       = module.compute.container_registry_admin_username
  sensitive   = true
}

# Monitoring Outputs
output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics Workspace"
  value       = module.monitoring.log_analytics_workspace_id
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key for Application Insights"
  value       = module.monitoring.application_insights_instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Connection string for Application Insights"
  value       = module.monitoring.application_insights_connection_string
  sensitive   = true
}

# Resource Group Output
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}

# Environment Information
output "environment_info" {
  description = "Environment information"
  value = {
    project_name = var.project_name
    environment  = var.environment
    location     = var.location
    deployed_at  = timestamp()
  }
}