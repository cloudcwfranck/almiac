# Spoke Virtual Network Module
# Deploys spoke network and peers with hub

resource "azurerm_virtual_network" "spoke" {
  name                = var.spoke_vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.spoke_address_space

  tags = var.tags
}

# Subnets
resource "azurerm_subnet" "workload" {
  for_each = var.workload_subnets

  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [each.value.address_prefix]
  service_endpoints    = lookup(each.value, "service_endpoints", [])

  dynamic "delegation" {
    for_each = lookup(each.value, "delegation", null) != null ? [each.value.delegation] : []
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_name
        actions = lookup(delegation.value, "actions", [])
      }
    }
  }
}

# Network Security Groups
resource "azurerm_network_security_group" "workload" {
  for_each = var.workload_subnets

  name                = "${each.key}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# NSG Associations
resource "azurerm_subnet_network_security_group_association" "workload" {
  for_each = var.workload_subnets

  subnet_id                 = azurerm_subnet.workload[each.key].id
  network_security_group_id = azurerm_network_security_group.workload[each.key].id
}

# VNet Peering: Spoke to Hub
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                         = "peer-${var.spoke_vnet_name}-to-hub"
  resource_group_name          = var.resource_group_name
  virtual_network_name         = azurerm_virtual_network.spoke.name
  remote_virtual_network_id    = var.hub_vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = var.use_remote_gateways
}

# VNet Peering: Hub to Spoke
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                         = "peer-hub-to-${var.spoke_vnet_name}"
  resource_group_name          = var.hub_resource_group_name
  virtual_network_name         = var.hub_vnet_name
  remote_virtual_network_id    = azurerm_virtual_network.spoke.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = var.hub_allow_gateway_transit
  use_remote_gateways          = false
}

# Route Table
resource "azurerm_route_table" "spoke" {
  count = var.enable_route_table ? 1 : 0

  name                          = "${var.spoke_vnet_name}-rt"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  disable_bgp_route_propagation = var.disable_bgp_route_propagation

  tags = var.tags
}

# Default Route to Firewall
resource "azurerm_route" "default_to_firewall" {
  count = var.enable_route_table && var.firewall_private_ip != null ? 1 : 0

  name                   = "default-to-firewall"
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.spoke[0].name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.firewall_private_ip
}

# Route Table Associations
resource "azurerm_subnet_route_table_association" "workload" {
  for_each = var.enable_route_table ? var.workload_subnets : {}

  subnet_id      = azurerm_subnet.workload[each.key].id
  route_table_id = azurerm_route_table.spoke[0].id
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "spoke_vnet" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "diag-${var.spoke_vnet_name}"
  target_resource_id         = azurerm_virtual_network.spoke.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "VMProtectionAlerts"
  }

  metric {
    category = "AllMetrics"
  }
}
