# Individual resource name outputs are defined in main.tf
# This file contains additional grouped outputs

output "names" {
  description = "Map of all resource names"
  value = {
    resource_group                = "rg-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
    virtual_network               = "vnet-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
    subnet                        = "snet-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
    network_security_group        = "nsg-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
    network_interface             = "nic-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
    public_ip                     = "pip-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
    load_balancer                 = "lb-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
    application_gateway           = "agw-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
    azure_firewall                = "afw-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
    bastion                       = "bas-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
    route_table                   = "rt-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
    virtual_network_gateway       = "vgw-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
    log_analytics_workspace       = "law-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
    application_insights          = "appi-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
    automation_account            = "aa-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
    recovery_services_vault       = "rsv-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
    key_vault                     = substr("kv-${local.workload_slug}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}", 0, 24)
    storage_account               = substr("st${local.workload_slug}${local.env_abbr}${local.region_abbr}${local.instance_suffix != null ? local.instance_suffix : ""}", 0, 24)
    storage_account_diagnostics   = substr("stdiag${local.workload_slug}${local.env_abbr}${local.region_abbr}${local.instance_suffix != null ? local.instance_suffix : ""}", 0, 24)
    aks_cluster                   = "aks-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
    container_registry            = substr("acr${local.workload_slug}${local.env_abbr}${local.region_abbr}${local.instance_suffix != null ? local.instance_suffix : ""}", 0, 50)
    virtual_machine               = substr("vm-${local.workload_slug}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}", 0, var.os_type == "windows" ? 15 : 64)
    sql_server                    = "sql-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
    sql_database                  = "sqldb-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
    cosmos_db                     = "cosmos-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
    app_service_plan              = "asp-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
    app_service                   = "app-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
    function_app                  = "func-${var.workload_name}-${local.env_abbr}-${local.region_abbr}${local.instance_suffix != null ? "-${local.instance_suffix}" : ""}"
  }
}

output "tags" {
  description = "Standard tags based on naming convention"
  value = {
    Environment = local.env_abbr
    Workload    = var.workload_name
    Location    = var.location
    ManagedBy   = "Terraform"
  }
}
