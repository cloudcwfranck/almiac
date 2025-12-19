# CAF Naming Module
# Generates Azure resource names following Cloud Adoption Framework standards
# Format: {resourceType}-{workload}-{environment}-{region}-{instance}

locals {
  # Region abbreviations
  region_abbreviations = {
    # Azure Commercial
    "eastus"             = "eus"
    "eastus2"            = "eus2"
    "westus"             = "wus"
    "westus2"            = "wus2"
    "centralus"          = "cus"
    "northcentralus"     = "ncus"
    "southcentralus"     = "scus"
    "westcentralus"      = "wcus"
    "canadacentral"      = "cac"
    "canadaeast"         = "cae"
    "brazilsouth"        = "brs"
    "northeurope"        = "neu"
    "westeurope"         = "weu"
    "uksouth"            = "uks"
    "ukwest"             = "ukw"
    "francecentral"      = "frc"
    "germanywestcentral" = "gwc"
    "switzerlandnorth"   = "swn"
    "norwayeast"         = "noe"
    "swedencentral"      = "swc"
    "eastasia"           = "eas"
    "southeastasia"      = "seas"
    "japaneast"          = "jpe"
    "japanwest"          = "jpw"
    "australiaeast"      = "aue"
    "australiasoutheast" = "ause"
    "centralindia"       = "cin"
    "southindia"         = "sin"
    "westindia"          = "win"
    "koreacentral"       = "koc"
    "koreasouth"         = "kos"
    "southafricanorth"   = "san"
    "uaenorth"           = "uan"
    
    # Azure Government
    "usgovvirginia" = "ugv"
    "usgovtexas"    = "ugt"
    "usgovarizona"  = "uga"
    "usdodeast"     = "ude"
    "usdodcentral"  = "udc"
  }

  # Environment abbreviations
  environment_abbreviations = {
    "development" = "dev"
    "dev"         = "dev"
    "staging"     = "stg"
    "stg"         = "stg"
    "production"  = "prod"
    "prod"        = "prod"
    "sandbox"     = "sbx"
    "sbx"         = "sbx"
  }

  # Get abbreviations
  region_abbr = lookup(local.region_abbreviations, var.location, "unknown")
  env_abbr    = lookup(local.environment_abbreviations, var.environment, var.environment)

  # Common name components
  workload_slug   = lower(replace(var.workload_name, "/[^a-zA-Z0-9]/", ""))
  instance_suffix = var.instance_number != null ? format("%03d", var.instance_number) : null
}

# Resource naming outputs
output "resource_group_name" {
  description = "Resource group name following CAF standards"
  value       = "rg-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
}

output "virtual_network_name" {
  description = "Virtual network name following CAF standards"
  value       = "vnet-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
}

output "subnet_name" {
  description = "Subnet name following CAF standards"
  value       = "snet-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
}

output "network_security_group_name" {
  description = "Network security group name following CAF standards"
  value       = "nsg-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
}

output "public_ip_name" {
  description = "Public IP name following CAF standards"
  value       = "pip-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
}

output "network_interface_name" {
  description = "Network interface name following CAF standards"
  value       = "nic-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
}

output "load_balancer_name" {
  description = "Load balancer name following CAF standards"
  value       = "lb-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
}

output "application_gateway_name" {
  description = "Application gateway name following CAF standards"
  value       = "agw-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
}

output "azure_firewall_name" {
  description = "Azure Firewall name following CAF standards"
  value       = "afw-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
}

output "bastion_name" {
  description = "Bastion host name following CAF standards"
  value       = "bas-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
}

output "route_table_name" {
  description = "Route table name following CAF standards"
  value       = "rt-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
}

output "virtual_network_gateway_name" {
  description = "Virtual network gateway name following CAF standards"
  value       = "vgw-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
}

output "log_analytics_workspace_name" {
  description = "Log Analytics workspace name following CAF standards"
  value       = "law-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
}

output "application_insights_name" {
  description = "Application Insights name following CAF standards"
  value       = "appi-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
}

output "automation_account_name" {
  description = "Automation account name following CAF standards"
  value       = "aa-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
}

output "recovery_services_vault_name" {
  description = "Recovery Services vault name following CAF standards"
  value       = "rsv-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
}

output "key_vault_name" {
  description = "Key Vault name following CAF standards (max 24 chars, alphanumeric and hyphens)"
  value       = substr("kv-${local.workload_slug}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}", 0, 24)
}

output "storage_account_name" {
  description = "Storage account name following CAF standards (lowercase alphanumeric only, max 24 chars)"
  value       = substr("st${local.workload_slug}${local.env_abbr}${local.region_abbr}${local.instance_suffix != null ? local.instance_suffix : ""}", 0, 24)
}

output "storage_account_diagnostics_name" {
  description = "Diagnostics storage account name following CAF standards"
  value       = substr("stdiag${local.workload_slug}${local.env_abbr}${local.region_abbr}${local.instance_suffix != null ? local.instance_suffix : ""}", 0, 24)
}

output "aks_cluster_name" {
  description = "AKS cluster name following CAF standards"
  value       = "aks-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
}

output "container_registry_name" {
  description = "Container registry name following CAF standards (alphanumeric only)"
  value       = substr("acr${local.workload_slug}${local.env_abbr}${local.region_abbr}${local.instance_suffix != null ? local.instance_suffix : ""}", 0, 50)
}

output "virtual_machine_name" {
  description = "Virtual machine name following CAF standards (max 15 chars for Windows)"
  value       = substr("vm-${local.workload_slug}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}", 0, var.os_type == "windows" ? 15 : 64)
}

output "sql_server_name" {
  description = "SQL Server name following CAF standards"
  value       = "sql-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
}

output "sql_database_name" {
  description = "SQL Database name following CAF standards"
  value       = "sqldb-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
}

output "cosmos_db_name" {
  description = "Cosmos DB account name following CAF standards"
  value       = "cosmos-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
}

output "app_service_plan_name" {
  description = "App Service Plan name following CAF standards"
  value       = "asp-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
}

output "app_service_name" {
  description = "App Service name following CAF standards"
  value       = "app-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
}

output "function_app_name" {
  description = "Function App name following CAF standards"
  value       = "func-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
}

# Additional outputs for common names
output "common" {
  description = "Common naming components"
  value = {
    workload    = var.workload_name
    environment = local.env_abbr
    region      = local.region_abbr
    location    = var.location
    instance    = local.instance_suffix
  }
}

# Generate custom resource name
output "custom_name" {
  description = "Custom resource name with provided prefix"
  value       = var.custom_prefix != null ? "${var.custom_prefix}-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}" : null
}
