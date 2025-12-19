# Hub Network Module Outputs

#
# Virtual Network
#

output "hub_vnet_id" {
  description = "ID of the hub virtual network"
  value       = azurerm_virtual_network.hub.id
}

output "hub_vnet_name" {
  description = "Name of the hub virtual network"
  value       = azurerm_virtual_network.hub.name
}

output "hub_vnet_address_space" {
  description = "Address space of the hub virtual network"
  value       = azurerm_virtual_network.hub.address_space
}

output "hub_resource_group_name" {
  description = "Name of the hub resource group"
  value       = var.resource_group_name
}

#
# Subnet IDs
#

output "firewall_subnet_id" {
  description = "ID of the Azure Firewall subnet"
  value       = azurerm_subnet.firewall.id
}

output "bastion_subnet_id" {
  description = "ID of the Azure Bastion subnet"
  value       = azurerm_subnet.bastion.id
}

output "gateway_subnet_id" {
  description = "ID of the Gateway subnet"
  value       = azurerm_subnet.gateway.id
}

output "management_subnet_id" {
  description = "ID of the management subnet"
  value       = azurerm_subnet.management.id
}

output "shared_services_subnet_id" {
  description = "ID of the shared services subnet"
  value       = azurerm_subnet.shared_services.id
}

output "subnet_ids" {
  description = "Map of all subnet IDs"
  value = {
    firewall        = azurerm_subnet.firewall.id
    bastion         = azurerm_subnet.bastion.id
    gateway         = azurerm_subnet.gateway.id
    management      = azurerm_subnet.management.id
    shared_services = azurerm_subnet.shared_services.id
  }
}

#
# Azure Firewall
#

output "firewall_id" {
  description = "ID of the Azure Firewall"
  value       = azurerm_firewall.hub.id
}

output "firewall_name" {
  description = "Name of the Azure Firewall"
  value       = azurerm_firewall.hub.name
}

output "firewall_public_ip" {
  description = "Public IP address of the Azure Firewall"
  value       = azurerm_public_ip.firewall.ip_address
}

output "firewall_private_ip" {
  description = "Private IP address of the Azure Firewall"
  value       = azurerm_firewall.hub.ip_configuration[0].private_ip_address
}

output "firewall_policy_id" {
  description = "ID of the Azure Firewall Policy"
  value       = azurerm_firewall_policy.hub.id
}

#
# Azure Bastion
#

output "bastion_id" {
  description = "ID of the Azure Bastion host"
  value       = azurerm_bastion_host.hub.id
}

output "bastion_name" {
  description = "Name of the Azure Bastion host"
  value       = azurerm_bastion_host.hub.name
}

output "bastion_dns_name" {
  description = "DNS name of the Azure Bastion host"
  value       = azurerm_bastion_host.hub.dns_name
}

output "bastion_public_ip" {
  description = "Public IP address of the Azure Bastion"
  value       = azurerm_public_ip.bastion.ip_address
}

#
# VPN Gateway
#

output "vpn_gateway_id" {
  description = "ID of the VPN Gateway"
  value       = var.enable_vpn_gateway ? azurerm_virtual_network_gateway.vpn[0].id : null
}

output "vpn_gateway_name" {
  description = "Name of the VPN Gateway"
  value       = var.enable_vpn_gateway ? azurerm_virtual_network_gateway.vpn[0].name : null
}

output "vpn_gateway_public_ip" {
  description = "Primary public IP address of the VPN Gateway"
  value       = var.enable_vpn_gateway ? azurerm_public_ip.vpn_gateway[0].ip_address : null
}

output "vpn_gateway_bgp_settings" {
  description = "BGP settings of the VPN Gateway"
  value       = var.enable_vpn_gateway && var.vpn_gateway_enable_bgp ? azurerm_virtual_network_gateway.vpn[0].bgp_settings : null
}

#
# ExpressRoute Gateway
#

output "expressroute_gateway_id" {
  description = "ID of the ExpressRoute Gateway"
  value       = var.enable_expressroute_gateway ? azurerm_virtual_network_gateway.expressroute[0].id : null
}

output "expressroute_gateway_name" {
  description = "Name of the ExpressRoute Gateway"
  value       = var.enable_expressroute_gateway ? azurerm_virtual_network_gateway.expressroute[0].name : null
}

#
# Private DNS Zones
#

output "private_dns_zone_ids" {
  description = "Map of private DNS zone IDs"
  value = {
    blob        = azurerm_private_dns_zone.blob.id
    file        = azurerm_private_dns_zone.file.id
    queue       = azurerm_private_dns_zone.queue.id
    table       = azurerm_private_dns_zone.table.id
    keyvault    = azurerm_private_dns_zone.keyvault.id
    sql         = azurerm_private_dns_zone.sql.id
    acr         = azurerm_private_dns_zone.acr.id
    appservice  = azurerm_private_dns_zone.appservice.id
    cosmos_sql  = azurerm_private_dns_zone.cosmos_sql.id
  }
}

output "private_dns_zone_names" {
  description = "Map of private DNS zone names"
  value = {
    blob        = azurerm_private_dns_zone.blob.name
    file        = azurerm_private_dns_zone.file.name
    queue       = azurerm_private_dns_zone.queue.name
    table       = azurerm_private_dns_zone.table.name
    keyvault    = azurerm_private_dns_zone.keyvault.name
    sql         = azurerm_private_dns_zone.sql.name
    acr         = azurerm_private_dns_zone.acr.name
    appservice  = azurerm_private_dns_zone.appservice.name
    cosmos_sql  = azurerm_private_dns_zone.cosmos_sql.name
  }
}

#
# Route Table
#

output "route_table_id" {
  description = "ID of the hub route table"
  value       = azurerm_route_table.hub_subnets.id
}

output "route_table_name" {
  description = "Name of the hub route table"
  value       = azurerm_route_table.hub_subnets.name
}

#
# Network Security Groups
#

output "nsg_ids" {
  description = "Map of NSG IDs"
  value = {
    firewall        = azurerm_network_security_group.firewall.id
    management      = azurerm_network_security_group.management.id
    shared_services = azurerm_network_security_group.shared_services.id
  }
}

#
# Network Watcher
#

output "network_watcher_id" {
  description = "ID of the Network Watcher"
  value       = var.enable_network_watcher ? azurerm_network_watcher.hub[0].id : null
}

output "flow_logs_storage_account_id" {
  description = "ID of the storage account for NSG flow logs"
  value       = var.enable_nsg_flow_logs ? azurerm_storage_account.flow_logs[0].id : null
}

#
# DDoS Protection
#

output "ddos_protection_plan_id" {
  description = "ID of the DDoS Protection Plan"
  value       = var.enable_ddos_protection ? azurerm_network_ddos_protection_plan.hub[0].id : null
}

#
# Computed Values
#

output "location" {
  description = "Azure region of the hub network"
  value       = var.location
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "naming_prefix" {
  description = "Naming prefix used for resources"
  value       = local.naming_prefix
}
