# Core Variables
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "webapp"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

variable "owner" {
  description = "Project owner"
  type        = string
  default     = "DevOps Team"
}

# Networking Variables
variable "vnet_address_space" {
  description = "Address space for VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_spaces" {
  description = "Address spaces for subnets"
  type = object({
    gateway  = list(string)
    app      = list(string)
    database = list(string)
  })
  default = {
    gateway  = ["10.0.1.0/24"]
    app      = ["10.0.2.0/24"]
    database = ["10.0.3.0/24"]
  }
}

# App Service Variables
variable "app_service_sku" {
  description = "App Service plan SKU"
  type = object({
    tier = string
    size = string
  })
  default = {
    tier = "Standard"
    size = "S1"
  }
}

# Database Variables
variable "database_config" {
  description = "Database configuration"
  type = object({
    sku_name                     = string
    storage_mb                   = number
    backup_retention_days        = number
    geo_redundant_backup_enabled = bool
    auto_grow_enabled           = bool
    version                     = string
  })
  default = {
    sku_name                     = "B_Gen5_1"
    storage_mb                   = 5120
    backup_retention_days        = 7
    geo_redundant_backup_enabled = false
    auto_grow_enabled           = true
    version                     = "13"
  }
}

# Storage Variables
variable "storage_config" {
  description = "Storage account configuration"
  type = object({
    account_tier             = string
    account_replication_type = string
    enable_static_website    = bool
  })
  default = {
    account_tier             = "Standard"
    account_replication_type = "LRS"
    enable_static_website    = true
  }
}

# Monitoring Variables
variable "log_retention_days" {
  description = "Log retention in days"
  type        = number
  default     = 30
}

# Security Variables
variable "allowed_ip_ranges" {
  description = "Allowed IP ranges for database access"
  type        = list(string)
  default     = []
}

variable "enable_private_endpoints" {
  description = "Enable private endpoints"
  type        = bool
  default     = false
}