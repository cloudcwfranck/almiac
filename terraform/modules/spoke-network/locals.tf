# Spoke Network Module - Local Values

locals {
  # Region abbreviations for naming
  region_abbreviations = {
    # US Commercial
    "eastus"         = "eus"
    "eastus2"        = "eus2"
    "westus"         = "wus"
    "westus2"        = "wus2"
    "centralus"      = "cus"
    "northcentralus" = "ncus"
    "southcentralus" = "scus"
    
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
  
  # Naming prefix (use provided or compute from workload-location-environment)
  naming_prefix = var.naming_prefix != null ? var.naming_prefix : "${var.workload_name}-${local.region_abbr}-${local.env_abbr}"

  # CAF-compliant resource names
  spoke_vnet_name   = "vnet-${local.naming_prefix}"
  route_table_name  = "rt-${local.naming_prefix}"

  # Merge default tags with provided tags
  default_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Module      = "spoke-network"
    Location    = var.location
    Workload    = var.workload_name
  }

  tags = merge(local.default_tags, var.tags)
}
