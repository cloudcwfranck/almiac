# Spoke Network Module
# Landing zone spoke network with hub peering, NSGs, and private endpoints

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
}

# Spoke Virtual Network
resource "azurerm_virtual_network" "spoke" {
  name                = local.spoke_vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.spoke_address_space

  tags = local.tags
}

#
# Subnets
#

resource "azurerm_subnet" "subnets" {
  for_each = var.subnets

  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [each.value.address_prefix]
  service_endpoints    = lookup(each.value, "service_endpoints", [])

  # Subnet delegation (e.g., for AKS, App Service, etc.)
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

  # Private endpoint network policies
  private_endpoint_network_policies_enabled     = lookup(each.value, "private_endpoint_network_policies_enabled", true)
  private_link_service_network_policies_enabled = lookup(each.value, "private_link_service_network_policies_enabled", true)
}

#
# Network Security Groups
#

resource "azurerm_network_security_group" "subnets" {
  for_each = var.subnets

  name                = "${each.key}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Default deny all inbound rule
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Custom security rules for this subnet
  dynamic "security_rule" {
    for_each = lookup(each.value, "security_rules", [])
    content {
      name                         = security_rule.value.name
      priority                     = security_rule.value.priority
      direction                    = security_rule.value.direction
      access                       = security_rule.value.access
      protocol                     = security_rule.value.protocol
      source_port_range            = lookup(security_rule.value, "source_port_range", null)
      source_port_ranges           = lookup(security_rule.value, "source_port_ranges", null)
      destination_port_range       = lookup(security_rule.value, "destination_port_range", null)
      destination_port_ranges      = lookup(security_rule.value, "destination_port_ranges", null)
      source_address_prefix        = lookup(security_rule.value, "source_address_prefix", null)
      source_address_prefixes      = lookup(security_rule.value, "source_address_prefixes", null)
      destination_address_prefix   = lookup(security_rule.value, "destination_address_prefix", null)
      destination_address_prefixes = lookup(security_rule.value, "destination_address_prefixes", null)
      description                  = lookup(security_rule.value, "description", null)
    }
  }

  tags = local.tags
}

# NSG Associations
resource "azurerm_subnet_network_security_group_association" "subnets" {
  for_each = var.subnets

  subnet_id                 = azurerm_subnet.subnets[each.key].id
  network_security_group_id = azurerm_network_security_group.subnets[each.key].id
}

#
# Route Table
#

resource "azurerm_route_table" "spoke" {
  name                          = local.route_table_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  disable_bgp_route_propagation = var.disable_bgp_route_propagation

  # Default route to hub firewall
  dynamic "route" {
    for_each = var.hub_firewall_private_ip != null ? [1] : []
    content {
      name                   = "default-via-hub-firewall"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = var.hub_firewall_private_ip
    }
  }

  # RFC1918 routes to hub firewall
  dynamic "route" {
    for_each = var.hub_firewall_private_ip != null ? ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"] : []
    content {
      name                   = "rfc1918-${replace(route.value, "/[./]/", "-")}-via-hub-firewall"
      address_prefix         = route.value
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = var.hub_firewall_private_ip
    }
  }

  # Custom routes
  dynamic "route" {
    for_each = var.custom_routes
    content {
      name                   = route.value.name
      address_prefix         = route.value.address_prefix
      next_hop_type          = route.value.next_hop_type
      next_hop_in_ip_address = lookup(route.value, "next_hop_in_ip_address", null)
    }
  }

  tags = local.tags
}

# Route table associations for subnets that need routing
resource "azurerm_subnet_route_table_association" "subnets" {
  for_each = {
    for k, v in var.subnets : k => v
    if lookup(v, "associate_route_table", true)
  }

  subnet_id      = azurerm_subnet.subnets[each.key].id
  route_table_id = azurerm_route_table.spoke.id
}

#
# VNet Peering to Hub
#

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                         = "peer-${local.spoke_vnet_name}-to-hub"
  resource_group_name          = var.resource_group_name
  virtual_network_name         = azurerm_virtual_network.spoke.name
  remote_virtual_network_id    = var.hub_vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = var.use_remote_gateways

  depends_on = [
    azurerm_virtual_network.spoke
  ]
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                         = "peer-hub-to-${local.spoke_vnet_name}"
  resource_group_name          = var.hub_resource_group_name
  virtual_network_name         = var.hub_vnet_name
  remote_virtual_network_id    = azurerm_virtual_network.spoke.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = var.hub_allow_gateway_transit
  use_remote_gateways          = false

  depends_on = [
    azurerm_virtual_network.spoke
  ]
}

#
# Private Endpoints
#

resource "azurerm_private_endpoint" "endpoints" {
  for_each = var.private_endpoints

  name                = "${each.key}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.subnets[each.value.subnet_name].id

  private_service_connection {
    name                           = "${each.key}-psc"
    private_connection_resource_id = each.value.private_connection_resource_id
    is_manual_connection           = lookup(each.value, "is_manual_connection", false)
    subresource_names              = each.value.subresource_names
    request_message                = lookup(each.value, "request_message", null)
  }

  dynamic "private_dns_zone_group" {
    for_each = lookup(each.value, "private_dns_zone_ids", null) != null ? [1] : []
    content {
      name                 = "${each.key}-dns-group"
      private_dns_zone_ids = each.value.private_dns_zone_ids
    }
  }

  tags = local.tags
}

#
# NSG Flow Logs
#

resource "azurerm_network_watcher_flow_log" "nsg_flow_logs" {
  for_each = var.enable_nsg_flow_logs ? var.subnets : {}

  name                 = "${azurerm_network_security_group.subnets[each.key].name}-flow-log"
  network_watcher_name = var.network_watcher_name
  resource_group_name  = var.network_watcher_resource_group_name

  network_security_group_id = azurerm_network_security_group.subnets[each.key].id
  storage_account_id        = var.flow_logs_storage_account_id
  enabled                   = true
  version                   = 2

  retention_policy {
    enabled = true
    days    = var.nsg_flow_logs_retention_days
  }

  dynamic "traffic_analytics" {
    for_each = var.enable_traffic_analytics && var.log_analytics_workspace_id != null ? [1] : []
    content {
      enabled               = true
      workspace_id          = var.log_analytics_workspace_id
      workspace_region      = var.location
      workspace_resource_id = var.log_analytics_resource_id
      interval_in_minutes   = 10
    }
  }

  tags = local.tags
}

#
# Diagnostic Settings
#

resource "azurerm_monitor_diagnostic_setting" "spoke_vnet" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "diag-${azurerm_virtual_network.spoke.name}"
  target_resource_id         = azurerm_virtual_network.spoke.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "VMProtectionAlerts"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# NSG Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "nsg" {
  for_each = var.log_analytics_workspace_id != null ? var.subnets : {}

  name                       = "diag-${azurerm_network_security_group.subnets[each.key].name}"
  target_resource_id         = azurerm_network_security_group.subnets[each.key].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }

  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}
