# Configure the Azure Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.1"
    }
  }
  
  backend "azurerm" {
    # Backend configuration will be provided during init
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Data sources
data "azurerm_client_config" "current" {}

# Random password for database
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-${var.environment}-rg"
  location = var.location
  
  tags = local.common_tags
}

# Networking Module
module "networking" {
  source = "./modules/networking"
  
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  project_name       = var.project_name
  environment        = var.environment
  
  vnet_address_space     = var.vnet_address_space
  subnet_address_spaces  = var.subnet_address_spaces
  
  tags = local.common_tags
}

# Key Vault Module
module "key_vault" {
  source = "./modules/security"
  
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  project_name       = var.project_name
  environment        = var.environment
  
  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.azurerm_client_config.current.object_id
  
  tags = local.common_tags
}

# Database Module
module "database" {
  source = "./modules/database"
  
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  project_name       = var.project_name
  environment        = var.environment
  
  subnet_id           = module.networking.database_subnet_id
  admin_password      = random_password.db_password.result
  key_vault_id        = module.key_vault.key_vault_id
  
  tags = local.common_tags
}

# Storage Module
module "storage" {
  source = "./modules/storage"
  
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  project_name       = var.project_name
  environment        = var.environment
  
  tags = local.common_tags
}

# Compute Module
module "compute" {
  source = "./modules/compute"
  
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  project_name       = var.project_name
  environment        = var.environment
  
  subnet_id               = module.networking.app_subnet_id
  database_connection_string = module.database.connection_string
  storage_connection_string  = module.storage.connection_string
  
  tags = local.common_tags
}

# Application Gateway
module "application_gateway" {
  source = "./modules/networking/app_gateway"
  
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  project_name       = var.project_name
  environment        = var.environment
  
  subnet_id           = module.networking.gateway_subnet_id
  backend_pool_fqdns  = [module.compute.app_service_hostname]
  
  tags = local.common_tags
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"
  
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  project_name       = var.project_name
  environment        = var.environment
  
  app_service_id = module.compute.app_service_id
  
  tags = local.common_tags
}

# Local values
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = var.owner
  }
}