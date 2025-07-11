# App Service Plan
resource "azurerm_service_plan" "main" {
  name                = "${var.project_name}-${var.environment}-asp"
  location            = var.location
  resource_group_name = var.resource_group_name
  
  os_type  = "Linux"
  sku_name = var.app_service_sku_name
  
  tags = var.tags
}

# App Service
resource "azurerm_linux_web_app" "main" {
  name                = "${var.project_name}-${var.environment}-app"
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.main.id
  
  site_config {
    always_on         = true
    health_check_path = "/health"
    
    application_stack {
      node_version = "18-lts"
    }
    
    app_command_line = "npm start"
  }
  
  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "DATABASE_URL"                        = var.database_connection_string
    "STORAGE_CONNECTION_STRING"           = var.storage_connection_string
    "NODE_ENV"                           = var.environment
    "APPINSIGHTS_INSTRUMENTATIONKEY"     = var.app_insights_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.app_insights_connection_string
  }
  
  connection_string {
    name  = "Database"
    type  = "PostgreSQL"
    value = var.database_connection_string
  }
  
  identity {
    type = "SystemAssigned"
  }
  
  tags = var.tags
}

# Virtual Network Integration
resource "azurerm_app_service_virtual_network_swift_connection" "main" {
  app_service_id = azurerm_linux_web_app.main.id
  subnet_id      = var.subnet_id
}

# App Service Slot for Staging
resource "azurerm_linux_web_app_slot" "staging" {
  count           = var.environment == "prod" ? 1 : 0
  name            = "staging"
  app_service_id  = azurerm_linux_web_app.main.id
  
  site_config {
    always_on         = true
    health_check_path = "/health"
    
    application_stack {
      node_version = "18-lts"
    }
    
    app_command_line = "npm start"
  }
  
  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "DATABASE_URL"                        = var.database_connection_string
    "STORAGE_CONNECTION_STRING"           = var.storage_connection_string
    "NODE_ENV"                           = "staging"
    "APPINSIGHTS_INSTRUMENTATIONKEY"     = var.app_insights_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.app_insights_connection_string
  }
  
  tags = var.tags
}

# Auto Scaling Rules
resource "azurerm_monitor_autoscale_setting" "main" {
  name                = "${var.project_name}-${var.environment}-autoscale"
  resource_group_name = var.resource_group_name
  location            = var.location
  target_resource_id  = azurerm_service_plan.main.id
  
  profile {
    name = "defaultProfile"
    
    capacity {
      default = 2
      minimum = 1
      maximum = 10
    }
    
    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.main.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
      }
      
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
    
    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.main.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }
      
      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }
  
  tags = var.tags
}

# Container Registry (for future Docker deployments)
resource "azurerm_container_registry" "main" {
  name                = "${replace(var.project_name, "-", "")}${var.environment}acr"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = true
  
  tags = var.tags
}