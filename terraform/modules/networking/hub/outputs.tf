output "hub_vnet_id" {
  description = "ID of the hub virtual network"
  value       = azurerm_virtual_network.hub.id
}

output "hub_vnet_name" {
  description = "Name of the hub virtual network"
  value       = azurerm_virtual_network.hub.name
}

output "firewall_private_ip" {
  description = "Private IP of Azure Firewall"
  value       = var.enable_firewall ? azurerm_firewall.hub[0].ip_configuration[0].private_ip_address : null
}

output "firewall_id" {
  description = "ID of Azure Firewall"
  value       = var.enable_firewall ? azurerm_firewall.hub[0].id : null
}

output "bastion_id" {
  description = "ID of Azure Bastion"
  value       = var.enable_bastion ? azurerm_bastion_host.hub[0].id : null
}

output "vpn_gateway_id" {
  description = "ID of VPN Gateway"
  value       = var.enable_vpn_gateway ? azurerm_virtual_network_gateway.vpn[0].id : null
}

output "route_table_id" {
  description = "ID of the firewall route table"
  value       = var.enable_firewall ? azurerm_route_table.firewall[0].id : null
}
