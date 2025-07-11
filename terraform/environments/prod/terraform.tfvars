# Production Environment Configuration
project_name = "webapp"
environment  = "prod"
location     = "East US"
owner        = "DevOps Team"

# Networking Configuration
vnet_address_space = ["10.2.0.0/16"]
subnet_address_spaces = {
  gateway  = ["10.2.1.0/24"]
  app      = ["10.2.2.0/24"]
  database = ["10.2.3.0/24"]
}

# App Service Configuration (Premium tier for prod)
app_service_sku = {
  tier = "PremiumV3"
  size = "P1v3"
}

# Database Configuration (General Purpose tier for prod)
database_config = {
  sku_name                     = "GP_Gen5_4"
  storage_mb                   = 51200
  backup_retention_days        = 35
  geo_redundant_backup_enabled = true
  auto_grow_enabled           = true
  version                     = "13"
}

# Storage Configuration (Zone-redundant for prod)
storage_config = {
  account_tier             = "Standard"
  account_replication_type = "ZRS"
  enable_static_website    = true
}

# Monitoring Configuration
log_retention_days = 90

# Security Configuration
allowed_ip_ranges = [
  # Add your office/admin IP ranges here
  # "203.0.113.0/24"
]

enable_private_endpoints = true