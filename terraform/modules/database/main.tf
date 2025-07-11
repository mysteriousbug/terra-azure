# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "${var.project_name}-${var.environment}-postgres"
  resource_group_name    = var.resource_group_name
  location               = var.location
  version                = var.database_config.version
  delegated_subnet_id    = var.subnet_id
  private_dns_zone_id    = var.private_dns_zone_id
  
  administrator_login    = "pgadmin"
  administrator_password = var.admin_password
  
  zone = "1"
  
  storage_mb        = var.database_config.storage_mb
  sku_name          = var.database_config.sku_name
  backup_retention_days = var.database_config.backup_retention_days
  geo_redundant_backup_enabled = var.database_config.geo_redundant_backup_enabled
  auto_grow_enabled = var.database_config.auto_grow_enabled
  
  tags = var.tags
}

# Database
resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = "${var.project_name}_${var.environment}_db"
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# Database Configuration
resource "azurerm_postgresql_flexible_server_configuration" "log_statement" {
  name      = "log_statement"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "all"
}

resource "azurerm_postgresql_flexible_server_configuration" "log_min_duration_statement" {
  name      = "log_min_duration_statement"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "1000"
}

# Store database password in Key Vault
resource "azurerm_key_vault_secret" "db_password" {
  name         = "${var.project_name}-${var.environment}-db-password"
  value        = var.admin_password
  key_vault_id = var.key_vault_id
  
  tags = var.tags
}

# Store connection string in Key Vault
resource "azurerm_key_vault_secret" "db_connection_string" {
  name         = "${var.project_name}-${var.environment}-db-connection-string"
  value        = "postgresql://pgadmin:${urlencode(var.admin_password)}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${azurerm_postgresql_flexible_server_database.main.name}?sslmode=require"
  key_vault_id = var.key_vault_id
  
  tags = var.tags
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "main" {
  name               = "${var.project_name}-${var.environment}-postgres-diagnostics"
  target_resource_id = azurerm_postgresql_flexible_server.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  enabled_log {
    category = "PostgreSQLLogs"
    
    retention_policy {
      enabled = true
      days    = var.log_retention_days
    }
  }
  
  metric {
    category = "AllMetrics"
    
    retention_policy {
      enabled = true
      days    = var.log_retention_days
    }
  }
}

# Firewall Rules (for allowed IP ranges)
resource "azurerm_postgresql_flexible_server_firewall_rule" "allowed_ips" {
  count    = length(var.allowed_ip_ranges)
  name     = "AllowedIP-${count.index}"
  server_id = azurerm_postgresql_flexible_server.main.id
  start_ip_address = split("/", var.allowed_ip_ranges[count.index])[0]
  end_ip_address   = split("/", var.allowed_ip_ranges[count.index])[0]
}

# Database maintenance window
resource "azurerm_postgresql_flexible_server_configuration" "maintenance_work_mem" {
  name      = "maintenance_work_mem"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "2048000"
}

# Enable extensions
resource "azurerm_postgresql_flexible_server_configuration" "shared_preload_libraries" {
  name      = "shared_preload_libraries"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "pg_stat_statements,pg_buffercache"
}