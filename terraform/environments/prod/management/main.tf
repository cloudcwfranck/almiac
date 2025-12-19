# Production Management Subscription

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  environment = "prod"
  location    = "eastus"
  tags = {
    Environment        = "prod"
    CostCenter         = "IT-OPS-001"
    Owner              = "platform-team@company.com"
    Application        = "management"
    Criticality        = "Mission-Critical"
    DataClassification = "Internal"
    ManagedBy          = "Terraform"
  }
}

module "naming" {
  source = "../../../modules/naming"
  
  workload_name   = "management"
  environment     = local.environment
  location        = local.location
  instance_number = 1
}

resource "azurerm_resource_group" "management" {
  name     = module.naming.resource_group_name
  location = local.location
  tags     = local.tags
}

module "monitoring" {
  source = "../../../modules/monitoring"
  
  log_analytics_name        = module.naming.log_analytics_workspace_name
  automation_account_name   = module.naming.automation_account_name
  diagnostic_storage_name   = module.naming.storage_account_diagnostics_name
  resource_group_name       = azurerm_resource_group.management.name
  location                  = local.location
  environment               = local.environment
  subscription_id           = data.azurerm_client_config.current.subscription_id
  retention_in_days         = 90
  
  critical_alert_emails = ["oncall@company.com"]
  tags = local.tags
}

data "azurerm_client_config" "current" {}

output "log_analytics_workspace_id" {
  value = module.monitoring.log_analytics_workspace_id
}
