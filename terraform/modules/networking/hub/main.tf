# Hub Virtual Network Module
# Deploys hub network with firewall, bastion, and gateway options

# Hub Virtual Network
resource "azurerm_virtual_network" "hub" {
  name                = var.hub_vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.hub_address_space

  tags = var.tags
}

# Subnets
resource "azurerm_subnet" "firewall" {
  count = var.enable_firewall ? 1 : 0

  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.firewall_subnet_prefix]
}

resource "azurerm_subnet" "bastion" {
  count = var.enable_bastion ? 1 : 0

  name                 = "AzureBastionSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.bastion_subnet_prefix]
}

resource "azurerm_subnet" "gateway" {
  count = var.enable_vpn_gateway || var.enable_expressroute_gateway ? 1 : 0

  name                 = "GatewaySubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.gateway_subnet_prefix]
}

resource "azurerm_subnet" "management" {
  name                 = "snet-management"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.management_subnet_prefix]
}

# Azure Firewall Public IP
resource "azurerm_public_ip" "firewall" {
  count = var.enable_firewall ? 1 : 0

  name                = "${var.firewall_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.availability_zones

  tags = var.tags
}

# Azure Firewall
resource "azurerm_firewall" "hub" {
  count = var.enable_firewall ? 1 : 0

  name                = var.firewall_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = var.firewall_sku_name
  sku_tier            = var.firewall_sku_tier
  firewall_policy_id  = var.firewall_policy_id != null ? var.firewall_policy_id : (var.enable_firewall ? azurerm_firewall_policy.hub[0].id : null)
  zones               = var.availability_zones

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.firewall[0].id
    public_ip_address_id = azurerm_public_ip.firewall[0].id
  }

  tags = var.tags
}

# Azure Firewall Policy
resource "azurerm_firewall_policy" "hub" {
  count = var.enable_firewall && var.firewall_policy_id == null ? 1 : 0

  name                = "${var.firewall_name}-policy"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.firewall_sku_tier

  dns {
    proxy_enabled = true
  }

  threat_intelligence_mode = var.threat_intelligence_mode

  tags = var.tags
}

# Bastion Public IP
resource "azurerm_public_ip" "bastion" {
  count = var.enable_bastion ? 1 : 0

  name                = "${var.bastion_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

# Azure Bastion
resource "azurerm_bastion_host" "hub" {
  count = var.enable_bastion ? 1 : 0

  name                = var.bastion_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.bastion_sku

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion[0].id
    public_ip_address_id = azurerm_public_ip.bastion[0].id
  }

  tags = var.tags
}

# VPN Gateway Public IP
resource "azurerm_public_ip" "vpn_gateway" {
  count = var.enable_vpn_gateway ? 1 : 0

  name                = "${var.vpn_gateway_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.availability_zones

  tags = var.tags
}

# VPN Gateway
resource "azurerm_virtual_network_gateway" "vpn" {
  count = var.enable_vpn_gateway ? 1 : 0

  name                = var.vpn_gateway_name
  location            = var.location
  resource_group_name = var.resource_group_name

  type     = "Vpn"
  vpn_type = var.vpn_type
  sku      = var.vpn_gateway_sku

  active_active = var.vpn_active_active
  enable_bgp    = var.enable_bgp

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.vpn_gateway[0].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway[0].id
  }

  dynamic "bgp_settings" {
    for_each = var.enable_bgp ? [1] : []
    content {
      asn = var.bgp_asn
    }
  }

  tags = var.tags
}

# ExpressRoute Gateway
resource "azurerm_virtual_network_gateway" "expressroute" {
  count = var.enable_expressroute_gateway && !var.enable_vpn_gateway ? 1 : 0

  name                = var.expressroute_gateway_name
  location            = var.location
  resource_group_name = var.resource_group_name

  type = "ExpressRoute"
  sku  = var.expressroute_gateway_sku

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.er_gateway[0].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway[0].id
  }

  tags = var.tags
}

resource "azurerm_public_ip" "er_gateway" {
  count = var.enable_expressroute_gateway && !var.enable_vpn_gateway ? 1 : 0

  name                = "${var.expressroute_gateway_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

# Route Table for Firewall
resource "azurerm_route_table" "firewall" {
  count = var.enable_firewall ? 1 : 0

  name                          = "${var.hub_vnet_name}-firewall-rt"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  disable_bgp_route_propagation = false

  tags = var.tags
}

# Network Security Group for Management
resource "azurerm_network_security_group" "management" {
  name                = "${var.hub_vnet_name}-management-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "management" {
  subnet_id                 = azurerm_subnet.management.id
  network_security_group_id = azurerm_network_security_group.management.id
}
