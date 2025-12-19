# Hub Network Module - Local Values
# Computed values and naming conventions following CAF standards

locals {
  # Region abbreviations for naming
  region_abbreviations = {
    # US Commercial
    "eastus"        = "eus"
    "eastus2"       = "eus2"
    "westus"        = "wus"
    "westus2"       = "wus2"
    "westus3"       = "wus3"
    "centralus"     = "cus"
    "northcentralus" = "ncus"
    "southcentralus" = "scus"
    "westcentralus" = "wcus"
    
    # US Government
    "usgovvirginia" = "ugv"
    "usgovtexas"    = "ugt"
    "usgovarizona"  = "uga"
    "usdodeast"     = "ude"
    "usdodcentral"  = "udc"
    
    # Europe
    "westeurope"  = "weu"
    "northeurope" = "neu"
    
    # Asia
    "eastasia"      = "eas"
    "southeastasia" = "seas"
  }

  # Environment abbreviations
  environment_abbreviations = {
    "dev"     = "dev"
    "staging" = "stg"
    "prod"    = "prd"
    "sandbox" = "sbx"
  }

  # Computed values
  region_abbr = lookup(local.region_abbreviations, var.location, "unknown")
  env_abbr    = lookup(local.environment_abbreviations, var.environment, var.environment)
  
  # Naming prefix (use provided or compute from location-environment)
  naming_prefix = var.naming_prefix != null ? var.naming_prefix : "${local.region_abbr}-${local.env_abbr}"

  # CAF-compliant resource names
  hub_vnet_name                  = "vnet-hub-${local.naming_prefix}"
  management_subnet_name         = "snet-management-${local.naming_prefix}"
  shared_services_subnet_name    = "snet-shared-${local.naming_prefix}"
  firewall_name                  = "afw-${local.naming_prefix}"
  firewall_pip_name              = "pip-afw-${local.naming_prefix}"
  firewall_policy_name           = "afwp-${local.naming_prefix}"
  bastion_name                   = "bas-${local.naming_prefix}"
  bastion_pip_name               = "pip-bas-${local.naming_prefix}"
  vpn_gateway_name               = "vgw-${local.naming_prefix}"
  vpn_gateway_pip_name           = "pip-vgw-${local.naming_prefix}"
  er_gateway_name                = "ergw-${local.naming_prefix}"
  er_gateway_pip_name            = "pip-ergw-${local.naming_prefix}"
  ddos_plan_name                 = "ddos-${local.naming_prefix}"

  # Merge default tags with provided tags
  default_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Module      = "hub-network"
    Location    = var.location
    Workload    = "hub"
  }

  tags = merge(local.default_tags, var.tags)

  # Firewall private IP (first usable IP in subnet)
  firewall_private_ip = cidrhost(var.firewall_subnet_address_prefix, 4)
}
