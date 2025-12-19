# Production Connectivity Subscription
# Deploys hub network with firewall, bastion, and VPN gateway

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  
  backend "azurerm" {
    # Backend config provided via backend-config file or CLI
  }
}

provider "azurerm" {
  features {}
}

# Local variables
locals {
  environment = "prod"
  location    = "eastus"
  tags = {
    Environment        = "prod"
    CostCenter         = "NET-001"
    Owner              = "network-team@company.com"
    Application        = "connectivity"
    Criticality        = "Mission-Critical"
    DataClassification = "Internal"
    ManagedBy          = "Terraform"
  }
}

# Naming Convention
module "naming" {
  source = "../../../modules/naming"
  
  workload_name   = "hub"
  environment     = local.environment
  location        = local.location
  instance_number = 1
}

# Resource Group
resource "azurerm_resource_group" "connectivity" {
  name     = module.naming.resource_group_name
  location = local.location
  tags     = local.tags
}

# Hub Network Module
module "hub_network" {
  source = "../../../modules/networking/hub"
  
  hub_vnet_name            = module.naming.virtual_network_name
  resource_group_name      = azurerm_resource_group.connectivity.name
  location                 = local.location
  hub_address_space        = ["10.0.0.0/16"]
  
  # Subnets
  firewall_subnet_prefix    = "10.0.1.0/24"
  bastion_subnet_prefix     = "10.0.2.0/24"
  gateway_subnet_prefix     = "10.0.3.0/24"
  management_subnet_prefix  = "10.0.4.0/24"
  
  # Azure Firewall
  enable_firewall          = true
  firewall_name            = module.naming.azure_firewall_name
  firewall_sku_tier        = "Premium"
  threat_intelligence_mode = "Alert"
  
  # Bastion
  enable_bastion           = true
  bastion_name             = module.naming.bastion_name
  bastion_sku              = "Standard"
  
  # VPN Gateway
  enable_vpn_gateway       = true
  vpn_gateway_name         = module.naming.virtual_network_gateway_name
  vpn_gateway_sku          = "VpnGw2AZ"
  enable_bgp               = true
  
  # High Availability
  availability_zones       = ["1", "2", "3"]
  
  # Diagnostics
  log_analytics_workspace_id = data.terraform_remote_state.management.outputs.log_analytics_workspace_id
  
  tags = local.tags
}

# Data sources
data "terraform_remote_state" "management" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstatexxxxxx"
    container_name       = "tfstate"
    key                  = "prod/management/terraform.tfstate"
  }
}

# Outputs
output "hub_vnet_id" {
  description = "ID of hub virtual network"
  value       = module.hub_network.hub_vnet_id
}

output "firewall_private_ip" {
  description = "Private IP of Azure Firewall"
  value       = module.hub_network.firewall_private_ip
}

output "hub_vnet_name" {
  description = "Name of hub virtual network"
  value       = module.hub_network.hub_vnet_name
}
