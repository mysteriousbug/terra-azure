# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.project_name}-${var.environment}-logs"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  
  tags = var.tags
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = "${var.project_name}-${var.environment}-insights"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
  
  tags = var.tags
}

# Action Group for Alerts
resource "azurerm_monitor_action_group" "main" {
  name                = "${var.project_name}-${var.environment}-alerts"
  resource_group_name = var.resource_group_name
  short_name          = "alerts"
  
  email_receiver {
    name          = "admin-email"
    email_address = var.admin_email
  }
  
  webhook_receiver {
    name        = "slack-webhook"
    service_uri = var.slack_webhook_url
  }
  
  tags = var.tags
}

# Metric Alerts
resource "azurerm_monitor_metric_alert" "high_cpu" {
  name                = "${var.project_name}-${var.environment}-high-cpu"
  resource_group_name = var.resource_group_name
  scopes              = [var.app_service_id]
  description         = "Alert when CPU percentage is high"
  
  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "CpuPercentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
    
    dimension {
      name     = "Instance"
      operator = "Include"
      values   = ["*"]
    }
  }
  
  window_size        = "PT5M"
  frequency          = "PT1M"
  severity           = 2
  
  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
  
  tags = var.tags
}

resource "azurerm_monitor_metric_alert" "high_memory" {
  name                = "${var.project_name}-${var.environment}-high-memory"
  resource_group_name = var.resource_group_name
  scopes              = [var.app_service_id]
  description         = "Alert when memory percentage is high"
  
  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "MemoryPercentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85
  }
  
  window_size        = "PT5M"
  frequency          = "PT1M"
  severity           = 2
  
  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
  
  tags = var.tags
}

resource "azurerm_monitor_metric_alert" "high_response_time" {
  name                = "${var.project_name}-${var.environment}-high-response-time"
  resource_group_name = var.resource_group_name
  scopes              = [var.app_service_id]
  description         = "Alert when response time is high"
  
  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "AverageResponseTime"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 5
  }
  
  window_size        = "PT5M"
  frequency          = "PT1M"
  severity           = 2
  
  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
  
  tags = var.tags
}

# Availability Test
resource "azurerm_application_insights_web_test" "main" {
  name                    = "${var.project_name}-${var.environment}-availability"
  location                = var.location
  resource_group_name     = var.resource_group_name
  application_insights_id = azurerm_application_insights.main.id
  kind                    = "ping"
  frequency               = 300
  timeout                 = 60
  enabled                 = true
  geo_locations           = ["us-va-ash-azr", "us-tx-sn1-azr", "us-il-ch1-azr"]
  
  configuration = <<XML
<WebTest Name="${var.project_name}-${var.environment}-availability" Id="ABD48585-0831-40CB-9069-682A25A54A9B" Enabled="True" CssProjectStructure="" CssIteration="" Timeout="60" WorkItemIds="" xmlns="http://microsoft.com/schemas/VisualStudio/TeamTest/2010" Description="" CredentialUserName="" CredentialPassword="" PreAuthenticate="True" Proxy="default" StopOnError="False" RecordedResultFile="">
  <Items>
    <Request Method="GET" Guid="a5f10126-e4cd-570d-961c-cea43999a200" Version="1.1" Url="${var.app_service_url}" ThinkTime="0" Timeout="60" ParseDependentRequests="True" FollowRedirects="True" RecordResult="True" Cache="False" ResponseTimeGoal="0" Encoding="utf-8" ExpectedHttpStatusCode="200" ExpectedResponseUrl="" ReportingName="" IgnoreHttpStatusCode="False" />
  </Items>
</WebTest>
XML
  
  tags = var.tags
}

# Dashboard
resource "azurerm_dashboard" "main" {
  name                = "${var.project_name}-${var.environment}-dashboard"
  resource_group_name = var.resource_group_name
  location            = var.location
  
  dashboard_properties = jsonencode({
    lenses = {
      "0" = {
        order = 0
        parts = {
          "0" = {
            position = {
              x = 0
              y = 0
              rowSpan = 4
              colSpan = 6
            }
            metadata = {
              inputs = [
                {
                  name = "resourceTypeMode"
                  isOptional = true
                }
              ]
              type = "Extension/HubsExtension/PartType/MonitorChartPart"
              settings = {
                content = {
                  options = {
                    chart = {
                      metrics = [
                        {
                          resourceMetadata = {
                            id = var.app_service_id
                          }
                          name = "CpuPercentage"
                          aggregationType = 4
                          namespace = "Microsoft.Web/sites"
                          metricVisualization = {
                            displayName = "CPU Percentage"
                          }
                        }
                      ]
                      title = "CPU Usage"
                      titleKind = 2
                      visualization = {
                        chartType = 2
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  })
  
  tags = var.tags
}

# Workbook for detailed monitoring
resource "azurerm_application_insights_workbook" "main" {
  name                = "${var.project_name}-${var.environment}-workbook"
  resource_group_name = var.resource_group_name
  location            = var.location
  display_name        = "${var.project_name} ${var.environment} Monitoring"
  
  data_json = jsonencode({
    version = "Notebook/1.0"
    items = [
      {
        type = 3
        content = {
          version = "KqlItem/1.0"
          query = "requests | summarize RequestCount = count() by bin(timestamp, 5m) | render timechart"
          size = 0
          title = "Request Volume"
          timeContext = {
            durationMs = 3600000
          }
          queryType = 0
          resourceType = "microsoft.insights/components"
        }
      }
    ]
  })
  
  tags = var.tags
}