# Terraform Bootstrap
# Creates Azure Storage Account for Terraform state with locking

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {}
  environment = var.azure_environment
}

# Random suffix for globally unique names
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Resource Group for Terraform State
resource "azurerm_resource_group" "tfstate" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment       = var.environment
    ManagedBy         = "Terraform"
    Purpose           = "TerraformState"
    CostCenter        = var.cost_center
    DataClassification = "Confidential"
  }
}

# Storage Account for Terraform State
resource "azurerm_storage_account" "tfstate" {
  name                            = "${var.storage_account_prefix}${random_string.suffix.result}"
  resource_group_name             = azurerm_resource_group.tfstate.name
  location                        = azurerm_resource_group.tfstate.location
  account_tier                    = "Standard"
  account_replication_type        = var.storage_replication_type
  account_kind                    = "StorageV2"
  min_tls_version                 = "TLS1_2"
  enable_https_traffic_only       = true
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled = true
    
    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }
  }

  identity {
    type = "SystemAssigned"
  }

  tags = azurerm_resource_group.tfstate.tags
}

# Storage Container for Terraform State
resource "azurerm_storage_container" "tfstate" {
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

# Enable Soft Delete for Blobs
resource "azurerm_storage_account_network_rules" "tfstate" {
  storage_account_id = azurerm_storage_account.tfstate.id
  default_action     = var.enable_public_access ? "Allow" : "Deny"
  bypass             = ["AzureServices"]
  ip_rules           = var.allowed_ip_addresses
}

# Log Analytics Workspace for Diagnostics
resource "azurerm_log_analytics_workspace" "tfstate" {
  count = var.enable_diagnostics ? 1 : 0

  name                = "law-tfstate-${var.environment}-${var.location_abbreviation}"
  location            = azurerm_resource_group.tfstate.location
  resource_group_name = azurerm_resource_group.tfstate.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = azurerm_resource_group.tfstate.tags
}

# Diagnostic Settings for Storage Account
resource "azurerm_monitor_diagnostic_setting" "tfstate" {
  count = var.enable_diagnostics ? 1 : 0

  name                       = "diag-tfstate-storage"
  target_resource_id         = "${azurerm_storage_account.tfstate.id}/blobServices/default"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.tfstate[0].id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  metric {
    category = "Transaction"
  }
}

# Key Vault for Secrets (optional)
resource "azurerm_key_vault" "tfstate" {
  count = var.create_key_vault ? 1 : 0

  name                       = "kv-tfstate-${random_string.suffix.result}"
  location                   = azurerm_resource_group.tfstate.location
  resource_group_name        = azurerm_resource_group.tfstate.name
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 90
  purge_protection_enabled   = true

  tags = azurerm_resource_group.tfstate.tags
}

# Output Backend Configuration
output "backend_config" {
  description = "Terraform backend configuration"
  value = {
    resource_group_name  = azurerm_resource_group.tfstate.name
    storage_account_name = azurerm_storage_account.tfstate.name
    container_name       = azurerm_storage_container.tfstate.name
    key                  = "terraform.tfstate"
  }
}

output "backend_config_file" {
  description = "Backend configuration for copy-paste"
  value = <<-EOT
    terraform {
      backend "azurerm" {
        resource_group_name  = "${azurerm_resource_group.tfstate.name}"
        storage_account_name = "${azurerm_storage_account.tfstate.name}"
        container_name       = "${azurerm_storage_container.tfstate.name}"
        key                  = "terraform.tfstate"
      }
    }
  EOT
}
