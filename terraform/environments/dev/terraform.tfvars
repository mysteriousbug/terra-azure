# Development Environment Configuration
project_name = "webapp"
environment  = "dev"
location     = "East US"
owner        = "DevOps Team"

# Networking Configuration
vnet_address_space = ["10.0.0.0/16"]
subnet_address_spaces = {
  gateway  = ["10.0.1.0/24"]
  app      = ["10.0.2.0/24"]
  database = ["10.0.3.0/24"]
}

# App Service Configuration (Free tier for dev)
app_service_sku = {
  tier = "Free"
  size = "F1"
}

# Database Configuration (Basic tier for dev)
database_config = {
  sku_name                     = "B_Gen5_1"
  storage_mb                   = 5120
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled           = true
  version                     = "13"
}

# Storage Configuration
storage_config = {
  account_tier             = "Standard"
  account_replication_type = "LRS"
  enable_static_website    = true
}

# Monitoring Configuration
log_retention_days = 7

# Security Configuration
allowed_ip_ranges = [
  "10.0.0.0/8",    # Private networks
  "172.16.0.0/12", # Private networks
  "192.168.0.0/16" # Private networks
]

enable_private_endpoints = false