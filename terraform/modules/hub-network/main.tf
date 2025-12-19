# Hub Network Module
# Enterprise-grade hub network with Azure Firewall, Bastion, VPN/ExpressRoute Gateway
# Supports Azure Commercial and Azure Government clouds

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
}

# Hub Virtual Network
resource "azurerm_virtual_network" "hub" {
  name                = local.hub_vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.hub_address_space

  tags = local.tags
}

#
# Subnets
#

# Azure Firewall Subnet (minimum /26)
resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.firewall_subnet_address_prefix]
}

# Azure Bastion Subnet (minimum /26)
resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.bastion_subnet_address_prefix]
}

# Gateway Subnet (minimum /27 for VPN/ExpressRoute)
resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.gateway_subnet_address_prefix]
}

# Management Subnet (jump boxes, build agents)
resource "azurerm_subnet" "management" {
  name                 = local.management_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.management_subnet_address_prefix]
}

# Shared Services Subnet (DNS, AD DS, etc.)
resource "azurerm_subnet" "shared_services" {
  name                 = local.shared_services_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.shared_services_subnet_address_prefix]
}

#
# Network Security Groups
#

# Firewall Subnet NSG (Azure manages this, but we create for logging)
resource "azurerm_network_security_group" "firewall" {
  name                = "${local.hub_vnet_name}-firewall-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = local.tags
}

# Management Subnet NSG
resource "azurerm_network_security_group" "management" {
  name                = "${local.hub_vnet_name}-management-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Allow RDP from Bastion subnet
  security_rule {
    name                       = "Allow-RDP-From-Bastion"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.bastion_subnet_address_prefix
    destination_address_prefix = "*"
  }

  # Allow SSH from Bastion subnet
  security_rule {
    name                       = "Allow-SSH-From-Bastion"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.bastion_subnet_address_prefix
    destination_address_prefix = "*"
  }

  # Deny all other inbound
  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = local.tags
}

# Shared Services Subnet NSG
resource "azurerm_network_security_group" "shared_services" {
  name                = "${local.hub_vnet_name}-shared-services-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Allow DNS from VNet
  security_rule {
    name                       = "Allow-DNS-From-VNet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "53"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # Allow LDAP for AD DS
  security_rule {
    name                       = "Allow-LDAP-From-VNet"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["389", "636", "3268", "3269"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # Allow Kerberos
  security_rule {
    name                       = "Allow-Kerberos-From-VNet"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "88"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  tags = local.tags
}

# NSG Associations
resource "azurerm_subnet_network_security_group_association" "management" {
  subnet_id                 = azurerm_subnet.management.id
  network_security_group_id = azurerm_network_security_group.management.id
}

resource "azurerm_subnet_network_security_group_association" "shared_services" {
  subnet_id                 = azurerm_subnet.shared_services.id
  network_security_group_id = azurerm_network_security_group.shared_services.id
}

#
# DDoS Protection (Optional)
#

resource "azurerm_network_ddos_protection_plan" "hub" {
  count = var.enable_ddos_protection ? 1 : 0

  name                = local.ddos_plan_name
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = local.tags
}

#
# Azure Firewall
#

# Firewall Public IP
resource "azurerm_public_ip" "firewall" {
  name                = local.firewall_pip_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.availability_zones

  tags = local.tags
}

# Firewall Management Public IP (required for forced tunneling)
resource "azurerm_public_ip" "firewall_management" {
  count = var.enable_forced_tunneling ? 1 : 0

  name                = "${local.firewall_pip_name}-mgmt"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.availability_zones

  tags = local.tags
}

# Firewall Policy
resource "azurerm_firewall_policy" "hub" {
  name                     = local.firewall_policy_name
  location                 = var.location
  resource_group_name      = var.resource_group_name
  sku                      = var.firewall_sku_tier
  threat_intelligence_mode = "Alert"

  # DNS settings
  dns {
    proxy_enabled = true
    servers       = var.custom_dns_servers
  }

  # Threat Intelligence (Premium only)
  dynamic "threat_intelligence_allowlist" {
    for_each = var.firewall_sku_tier == "Premium" ? [1] : []
    content {
      ip_addresses = var.threat_intelligence_allowlist_ips
      fqdns        = var.threat_intelligence_allowlist_fqdns
    }
  }

  # Intrusion Detection and Prevention System (Premium only)
  dynamic "intrusion_detection" {
    for_each = var.firewall_sku_tier == "Premium" ? [1] : []
    content {
      mode = var.idps_mode

      dynamic "signature_overrides" {
        for_each = var.idps_signature_overrides
        content {
          id    = signature_overrides.value.id
          state = signature_overrides.value.state
        }
      }

      dynamic "traffic_bypass" {
        for_each = var.idps_traffic_bypass
        content {
          name                  = traffic_bypass.value.name
          protocol              = traffic_bypass.value.protocol
          description           = traffic_bypass.value.description
          destination_addresses = traffic_bypass.value.destination_addresses
          destination_ports     = traffic_bypass.value.destination_ports
          source_addresses      = traffic_bypass.value.source_addresses
          source_ip_groups      = traffic_bypass.value.source_ip_groups
        }
      }
    }
  }

  # TLS Inspection (Premium only)
  dynamic "tls_certificate" {
    for_each = var.firewall_sku_tier == "Premium" && var.enable_tls_inspection ? [1] : []
    content {
      key_vault_secret_id = var.tls_inspection_keyvault_secret_id
      name                = "tls-inspection-cert"
    }
  }

  tags = local.tags
}

# Firewall Policy - Network Rule Collection Group
resource "azurerm_firewall_policy_rule_collection_group" "network_rules" {
  name               = "NetworkRuleCollectionGroup"
  firewall_policy_id = azurerm_firewall_policy.hub.id
  priority           = 100

  # Allow Azure services
  network_rule_collection {
    name     = "AllowAzureServices"
    priority = 100
    action   = "Allow"

    rule {
      name                  = "AllowAzureCloud"
      protocols             = ["TCP", "UDP"]
      source_addresses      = ["*"]
      destination_addresses = ["AzureCloud"]
      destination_ports     = ["443", "80"]
    }

    rule {
      name                  = "AllowAzureMonitor"
      protocols             = ["TCP"]
      source_addresses      = ["*"]
      destination_addresses = ["AzureMonitor"]
      destination_ports     = ["443"]
    }
  }

  # Allow NTP
  network_rule_collection {
    name     = "AllowTimeSync"
    priority = 110
    action   = "Allow"

    rule {
      name                  = "AllowNTP"
      protocols             = ["UDP"]
      source_addresses      = ["*"]
      destination_addresses = ["*"]
      destination_ports     = ["123"]
    }
  }

  # Allow DNS
  network_rule_collection {
    name     = "AllowDNS"
    priority = 120
    action   = "Allow"

    rule {
      name                  = "AllowDNSOutbound"
      protocols             = ["UDP", "TCP"]
      source_addresses      = ["*"]
      destination_addresses = var.custom_dns_servers != null ? var.custom_dns_servers : ["168.63.129.16"]
      destination_ports     = ["53"]
    }
  }

  # Custom network rules
  dynamic "network_rule_collection" {
    for_each = var.custom_network_rules
    content {
      name     = network_rule_collection.value.name
      priority = network_rule_collection.value.priority
      action   = network_rule_collection.value.action

      dynamic "rule" {
        for_each = network_rule_collection.value.rules
        content {
          name                  = rule.value.name
          protocols             = rule.value.protocols
          source_addresses      = rule.value.source_addresses
          destination_addresses = rule.value.destination_addresses
          destination_ports     = rule.value.destination_ports
          source_ip_groups      = lookup(rule.value, "source_ip_groups", null)
          destination_ip_groups = lookup(rule.value, "destination_ip_groups", null)
        }
      }
    }
  }
}

# Firewall Policy - Application Rule Collection Group
resource "azurerm_firewall_policy_rule_collection_group" "application_rules" {
  name               = "ApplicationRuleCollectionGroup"
  firewall_policy_id = azurerm_firewall_policy.hub.id
  priority           = 200

  # Allow Windows Updates
  application_rule_collection {
    name     = "AllowWindowsUpdates"
    priority = 100
    action   = "Allow"

    rule {
      name = "WindowsUpdate"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses = ["*"]
      destination_fqdns = [
        "*.windowsupdate.microsoft.com",
        "*.update.microsoft.com",
        "*.windowsupdate.com",
        "*.download.windowsupdate.com",
        "*.download.microsoft.com",
        "*.dl.delivery.mp.microsoft.com",
        "*.prod.do.dsp.mp.microsoft.com"
      ]
    }
  }

  # Allow Azure/Microsoft services
  application_rule_collection {
    name     = "AllowMicrosoftServices"
    priority = 110
    action   = "Allow"

    rule {
      name = "AzureServices"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses = ["*"]
      destination_fqdns = [
        "*.azure.com",
        "*.microsoft.com",
        "*.msftauth.net",
        "*.windows.net"
      ]
    }
  }

  # Allow Ubuntu/Linux updates
  application_rule_collection {
    name     = "AllowLinuxUpdates"
    priority = 120
    action   = "Allow"

    rule {
      name = "UbuntuUpdates"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses = ["*"]
      destination_fqdns = [
        "*.ubuntu.com",
        "*.canonical.com",
        "security.ubuntu.com",
        "archive.ubuntu.com"
      ]
    }
  }

  # Custom application rules
  dynamic "application_rule_collection" {
    for_each = var.custom_application_rules
    content {
      name     = application_rule_collection.value.name
      priority = application_rule_collection.value.priority
      action   = application_rule_collection.value.action

      dynamic "rule" {
        for_each = application_rule_collection.value.rules
        content {
          name = rule.value.name

          dynamic "protocols" {
            for_each = rule.value.protocols
            content {
              type = protocols.value.type
              port = protocols.value.port
            }
          }

          source_addresses      = lookup(rule.value, "source_addresses", null)
          source_ip_groups      = lookup(rule.value, "source_ip_groups", null)
          destination_fqdns     = lookup(rule.value, "destination_fqdns", null)
          destination_fqdn_tags = lookup(rule.value, "destination_fqdn_tags", null)
        }
      }
    }
  }
}

# Firewall Policy - DNAT Rule Collection Group
resource "azurerm_firewall_policy_rule_collection_group" "dnat_rules" {
  count = length(var.dnat_rules) > 0 ? 1 : 0

  name               = "DNATRuleCollectionGroup"
  firewall_policy_id = azurerm_firewall_policy.hub.id
  priority           = 300

  dynamic "nat_rule_collection" {
    for_each = var.dnat_rules
    content {
      name     = nat_rule_collection.value.name
      priority = nat_rule_collection.value.priority
      action   = "Dnat"

      dynamic "rule" {
        for_each = nat_rule_collection.value.rules
        content {
          name                = rule.value.name
          protocols           = rule.value.protocols
          source_addresses    = rule.value.source_addresses
          destination_address = azurerm_public_ip.firewall.ip_address
          destination_ports   = rule.value.destination_ports
          translated_address  = rule.value.translated_address
          translated_port     = rule.value.translated_port
        }
      }
    }
  }
}

# Azure Firewall
resource "azurerm_firewall" "hub" {
  name                = local.firewall_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = var.firewall_sku_tier
  firewall_policy_id  = azurerm_firewall_policy.hub.id
  zones               = var.availability_zones

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }

  dynamic "management_ip_configuration" {
    for_each = var.enable_forced_tunneling ? [1] : []
    content {
      name                 = "management"
      subnet_id            = azurerm_subnet.firewall.id
      public_ip_address_id = azurerm_public_ip.firewall_management[0].id
    }
  }

  tags = local.tags
}

#
# Azure Bastion
#

# Bastion Public IP
resource "azurerm_public_ip" "bastion" {
  name                = local.bastion_pip_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.tags
}

# Azure Bastion Host
resource "azurerm_bastion_host" "hub" {
  name                = local.bastion_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.bastion_sku

  # Premium features
  copy_paste_enabled     = var.bastion_sku == "Premium" ? true : var.bastion_copy_paste_enabled
  file_copy_enabled      = var.bastion_sku == "Premium" ? var.bastion_file_copy_enabled : false
  ip_connect_enabled     = var.bastion_sku == "Premium" ? var.bastion_ip_connect_enabled : false
  shareable_link_enabled = var.bastion_sku == "Premium" ? var.bastion_shareable_link_enabled : false
  tunneling_enabled      = var.bastion_sku == "Premium" ? var.bastion_tunneling_enabled : false

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }

  tags = local.tags
}

# Continued in next file due to length...

#
# VPN Gateway
#

# VPN Gateway Public IP
resource "azurerm_public_ip" "vpn_gateway" {
  count = var.enable_vpn_gateway ? 1 : 0

  name                = local.vpn_gateway_pip_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.availability_zones

  tags = local.tags
}

# VPN Gateway Public IP (second for active-active)
resource "azurerm_public_ip" "vpn_gateway_secondary" {
  count = var.enable_vpn_gateway && var.vpn_gateway_active_active ? 1 : 0

  name                = "${local.vpn_gateway_pip_name}-secondary"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.availability_zones

  tags = local.tags
}

# VPN Gateway
resource "azurerm_virtual_network_gateway" "vpn" {
  count = var.enable_vpn_gateway ? 1 : 0

  name                = local.vpn_gateway_name
  location            = var.location
  resource_group_name = var.resource_group_name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = var.vpn_gateway_active_active
  enable_bgp    = var.vpn_gateway_enable_bgp
  sku           = var.vpn_gateway_sku

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.vpn_gateway[0].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway.id
  }

  dynamic "ip_configuration" {
    for_each = var.vpn_gateway_active_active ? [1] : []
    content {
      name                          = "vnetGatewayConfig2"
      public_ip_address_id          = azurerm_public_ip.vpn_gateway_secondary[0].id
      private_ip_address_allocation = "Dynamic"
      subnet_id                     = azurerm_subnet.gateway.id
    }
  }

  dynamic "bgp_settings" {
    for_each = var.vpn_gateway_enable_bgp ? [1] : []
    content {
      asn         = var.vpn_gateway_bgp_asn
      peer_weight = var.vpn_gateway_bgp_peer_weight

      dynamic "peering_addresses" {
        for_each = var.vpn_gateway_active_active ? [0, 1] : [0]
        content {
          ip_configuration_name = peering_addresses.value == 0 ? "vnetGatewayConfig" : "vnetGatewayConfig2"
          apipa_addresses       = var.vpn_gateway_bgp_apipa_addresses[peering_addresses.value]
        }
      }
    }
  }

  tags = local.tags
}

#
# ExpressRoute Gateway (Optional)
#

# ExpressRoute Gateway Public IP
resource "azurerm_public_ip" "er_gateway" {
  count = var.enable_expressroute_gateway ? 1 : 0

  name                = local.er_gateway_pip_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.tags
}

# ExpressRoute Gateway
resource "azurerm_virtual_network_gateway" "expressroute" {
  count = var.enable_expressroute_gateway ? 1 : 0

  name                = local.er_gateway_name
  location            = var.location
  resource_group_name = var.resource_group_name

  type = "ExpressRoute"
  sku  = var.expressroute_gateway_sku

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.er_gateway[0].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway.id
  }

  tags = local.tags
}

#
# Route Tables
#

# Route table for subnets (force traffic through firewall)
resource "azurerm_route_table" "hub_subnets" {
  name                          = "${local.hub_vnet_name}-rt"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  disable_bgp_route_propagation = false

  # Default route to firewall
  route {
    name                   = "default-to-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.hub.ip_configuration[0].private_ip_address
  }

  # RFC1918 routes to firewall
  route {
    name                   = "rfc1918-10-to-firewall"
    address_prefix         = "10.0.0.0/8"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.hub.ip_configuration[0].private_ip_address
  }

  route {
    name                   = "rfc1918-172-to-firewall"
    address_prefix         = "172.16.0.0/12"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.hub.ip_configuration[0].private_ip_address
  }

  route {
    name                   = "rfc1918-192-to-firewall"
    address_prefix         = "192.168.0.0/16"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.hub.ip_configuration[0].private_ip_address
  }

  tags = local.tags
}

# Associate route table with management subnet
resource "azurerm_subnet_route_table_association" "management" {
  subnet_id      = azurerm_subnet.management.id
  route_table_id = azurerm_route_table.hub_subnets.id
}

# Associate route table with shared services subnet
resource "azurerm_subnet_route_table_association" "shared_services" {
  subnet_id      = azurerm_subnet.shared_services.id
  route_table_id = azurerm_route_table.hub_subnets.id
}

#
# Private DNS Zones for Azure PaaS Services
#

# Storage - Blob
resource "azurerm_private_dns_zone" "blob" {
  name                = var.azure_cloud == "usgovernment" ? "privatelink.blob.core.usgovcloudapi.net" : "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name

  tags = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  name                  = "${azurerm_virtual_network.hub.name}-blob-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false

  tags = local.tags
}

# Storage - File
resource "azurerm_private_dns_zone" "file" {
  name                = var.azure_cloud == "usgovernment" ? "privatelink.file.core.usgovcloudapi.net" : "privatelink.file.core.windows.net"
  resource_group_name = var.resource_group_name

  tags = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "file" {
  name                  = "${azurerm_virtual_network.hub.name}-file-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.file.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false

  tags = local.tags
}

# Storage - Queue
resource "azurerm_private_dns_zone" "queue" {
  name                = var.azure_cloud == "usgovernment" ? "privatelink.queue.core.usgovcloudapi.net" : "privatelink.queue.core.windows.net"
  resource_group_name = var.resource_group_name

  tags = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "queue" {
  name                  = "${azurerm_virtual_network.hub.name}-queue-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.queue.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false

  tags = local.tags
}

# Storage - Table
resource "azurerm_private_dns_zone" "table" {
  name                = var.azure_cloud == "usgovernment" ? "privatelink.table.core.usgovcloudapi.net" : "privatelink.table.core.windows.net"
  resource_group_name = var.resource_group_name

  tags = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "table" {
  name                  = "${azurerm_virtual_network.hub.name}-table-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.table.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false

  tags = local.tags
}

# Key Vault
resource "azurerm_private_dns_zone" "keyvault" {
  name                = var.azure_cloud == "usgovernment" ? "privatelink.vaultcore.usgovcloudapi.net" : "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name

  tags = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "keyvault" {
  name                  = "${azurerm_virtual_network.hub.name}-keyvault-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false

  tags = local.tags
}

# SQL Database
resource "azurerm_private_dns_zone" "sql" {
  name                = var.azure_cloud == "usgovernment" ? "privatelink.database.usgovcloudapi.net" : "privatelink.database.windows.net"
  resource_group_name = var.resource_group_name

  tags = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql" {
  name                  = "${azurerm_virtual_network.hub.name}-sql-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false

  tags = local.tags
}

# Azure Container Registry
resource "azurerm_private_dns_zone" "acr" {
  name                = var.azure_cloud == "usgovernment" ? "privatelink.azurecr.us" : "privatelink.azurecr.io"
  resource_group_name = var.resource_group_name

  tags = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  name                  = "${azurerm_virtual_network.hub.name}-acr-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false

  tags = local.tags
}

# App Service
resource "azurerm_private_dns_zone" "appservice" {
  name                = var.azure_cloud == "usgovernment" ? "privatelink.azurewebsites.us" : "privatelink.azurewebsites.net"
  resource_group_name = var.resource_group_name

  tags = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "appservice" {
  name                  = "${azurerm_virtual_network.hub.name}-appservice-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.appservice.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false

  tags = local.tags
}

# Cosmos DB - SQL
resource "azurerm_private_dns_zone" "cosmos_sql" {
  name                = var.azure_cloud == "usgovernment" ? "privatelink.documents.azure.us" : "privatelink.documents.azure.com"
  resource_group_name = var.resource_group_name

  tags = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "cosmos_sql" {
  name                  = "${azurerm_virtual_network.hub.name}-cosmos-sql-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.cosmos_sql.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false

  tags = local.tags
}

#
# Network Watcher (one per region)
#

# Network Watcher Resource Group
resource "azurerm_resource_group" "network_watcher" {
  count = var.enable_network_watcher ? 1 : 0

  name     = "NetworkWatcherRG"
  location = var.location

  tags = local.tags
}

# Network Watcher
resource "azurerm_network_watcher" "hub" {
  count = var.enable_network_watcher ? 1 : 0

  name                = "NetworkWatcher_${var.location}"
  location            = var.location
  resource_group_name = azurerm_resource_group.network_watcher[0].name

  tags = local.tags
}

# Storage account for NSG flow logs
resource "azurerm_storage_account" "flow_logs" {
  count = var.enable_nsg_flow_logs ? 1 : 0

  name                     = replace(lower("${local.hub_vnet_name}flowlogs"), "-", "")
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  tags = local.tags
}

# NSG Flow Logs for Management NSG
resource "azurerm_network_watcher_flow_log" "management" {
  count = var.enable_nsg_flow_logs ? 1 : 0

  name                 = "${azurerm_network_security_group.management.name}-flow-log"
  network_watcher_name = azurerm_network_watcher.hub[0].name
  resource_group_name  = azurerm_resource_group.network_watcher[0].name

  network_security_group_id = azurerm_network_security_group.management.id
  storage_account_id        = azurerm_storage_account.flow_logs[0].id
  enabled                   = true
  version                   = 2

  retention_policy {
    enabled = true
    days    = var.nsg_flow_logs_retention_days
  }

  traffic_analytics {
    enabled               = var.enable_traffic_analytics
    workspace_id          = var.log_analytics_workspace_id
    workspace_region      = var.location
    workspace_resource_id = var.log_analytics_resource_id
    interval_in_minutes   = 10
  }

  tags = local.tags
}

# NSG Flow Logs for Shared Services NSG
resource "azurerm_network_watcher_flow_log" "shared_services" {
  count = var.enable_nsg_flow_logs ? 1 : 0

  name                 = "${azurerm_network_security_group.shared_services.name}-flow-log"
  network_watcher_name = azurerm_network_watcher.hub[0].name
  resource_group_name  = azurerm_resource_group.network_watcher[0].name

  network_security_group_id = azurerm_network_security_group.shared_services.id
  storage_account_id        = azurerm_storage_account.flow_logs[0].id
  enabled                   = true
  version                   = 2

  retention_policy {
    enabled = true
    days    = var.nsg_flow_logs_retention_days
  }

  traffic_analytics {
    enabled               = var.enable_traffic_analytics
    workspace_id          = var.log_analytics_workspace_id
    workspace_region      = var.location
    workspace_resource_id = var.log_analytics_resource_id
    interval_in_minutes   = 10
  }

  tags = local.tags
}

#
# Diagnostic Settings
#

# Firewall Diagnostics
resource "azurerm_monitor_diagnostic_setting" "firewall" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "diag-${azurerm_firewall.hub.name}"
  target_resource_id         = azurerm_firewall.hub.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AzureFirewallApplicationRule"
  }

  enabled_log {
    category = "AzureFirewallNetworkRule"
  }

  enabled_log {
    category = "AzureFirewallDnsProxy"
  }

  dynamic "enabled_log" {
    for_each = var.firewall_sku_tier == "Premium" ? ["AzureFirewallThreatIntel"] : []
    content {
      category = enabled_log.value
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# VNet Diagnostics
resource "azurerm_monitor_diagnostic_setting" "hub_vnet" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "diag-${azurerm_virtual_network.hub.name}"
  target_resource_id         = azurerm_virtual_network.hub.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "VMProtectionAlerts"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# VPN Gateway Diagnostics
resource "azurerm_monitor_diagnostic_setting" "vpn_gateway" {
  count = var.enable_vpn_gateway && var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "diag-${azurerm_virtual_network_gateway.vpn[0].name}"
  target_resource_id         = azurerm_virtual_network_gateway.vpn[0].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "GatewayDiagnosticLog"
  }

  enabled_log {
    category = "TunnelDiagnosticLog"
  }

  enabled_log {
    category = "RouteDiagnosticLog"
  }

  enabled_log {
    category = "IKEDiagnosticLog"
  }

  enabled_log {
    category = "P2SDiagnosticLog"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Bastion Diagnostics
resource "azurerm_monitor_diagnostic_setting" "bastion" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "diag-${azurerm_bastion_host.hub.name}"
  target_resource_id         = azurerm_bastion_host.hub.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "BastionAuditLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

#
# VNet Peering to Spokes
#

# Peering from Hub to Spokes
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  for_each = var.spoke_virtual_networks

  name                         = "peer-hub-to-${each.key}"
  resource_group_name          = var.resource_group_name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = each.value.vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = var.enable_vpn_gateway || var.enable_expressroute_gateway
  use_remote_gateways          = false

  depends_on = [
    azurerm_virtual_network_gateway.vpn,
    azurerm_virtual_network_gateway.expressroute
  ]
}
