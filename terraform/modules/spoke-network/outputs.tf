# Spoke Network Module Outputs

#
# Virtual Network
#

output "spoke_vnet_id" {
  description = "ID of the spoke virtual network"
  value       = azurerm_virtual_network.spoke.id
}

output "spoke_vnet_name" {
  description = "Name of the spoke virtual network"
  value       = azurerm_virtual_network.spoke.name
}

output "spoke_vnet_address_space" {
  description = "Address space of the spoke virtual network"
  value       = azurerm_virtual_network.spoke.address_space
}

output "spoke_resource_group_name" {
  description = "Name of the spoke resource group"
  value       = var.resource_group_name
}

#
# Subnets
#

output "subnet_ids" {
  description = "Map of subnet IDs"
  value       = { for k, v in azurerm_subnet.subnets : k => v.id }
}

output "subnet_address_prefixes" {
  description = "Map of subnet address prefixes"
  value       = { for k, v in azurerm_subnet.subnets : k => v.address_prefixes[0] }
}

#
# Network Security Groups
#

output "nsg_ids" {
  description = "Map of NSG IDs"
  value       = { for k, v in azurerm_network_security_group.subnets : k => v.id }
}

output "nsg_names" {
  description = "Map of NSG names"
  value       = { for k, v in azurerm_network_security_group.subnets : k => v.name }
}

#
# Route Table
#

output "route_table_id" {
  description = "ID of the spoke route table"
  value       = azurerm_route_table.spoke.id
}

output "route_table_name" {
  description = "Name of the spoke route table"
  value       = azurerm_route_table.spoke.name
}

#
# VNet Peering
#

output "peering_spoke_to_hub_id" {
  description = "ID of the spoke-to-hub peering"
  value       = azurerm_virtual_network_peering.spoke_to_hub.id
}

output "peering_hub_to_spoke_id" {
  description = "ID of the hub-to-spoke peering"
  value       = azurerm_virtual_network_peering.hub_to_spoke.id
}

#
# Private Endpoints
#

output "private_endpoint_ids" {
  description = "Map of private endpoint IDs"
  value       = { for k, v in azurerm_private_endpoint.endpoints : k => v.id }
}

output "private_endpoint_private_ips" {
  description = "Map of private endpoint IP addresses"
  value       = { for k, v in azurerm_private_endpoint.endpoints : k => v.private_service_connection[0].private_ip_address }
}

#
# Computed Values
#

output "location" {
  description = "Azure region of the spoke network"
  value       = var.location
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "workload_name" {
  description = "Workload name"
  value       = var.workload_name
}

output "naming_prefix" {
  description = "Naming prefix used for resources"
  value       = local.naming_prefix
}
