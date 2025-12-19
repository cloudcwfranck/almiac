# Hub Network Module Variables

#
# Basic Configuration
#

variable "resource_group_name" {
  description = "Name of the resource group for hub network resources"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string

  validation {
    condition = can(regex("^(eastus|westus|centralus|usgovvirginia|usgovtexas|usgovarizona|usdodeast|usdodcentral|westeurope|northeurope|southeastasia|eastasia)$", var.location))
    error_message = "Location must be a valid Azure region."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "sandbox"], var.environment)
    error_message = "Environment must be dev, staging, prod, or sandbox."
  }
}

variable "azure_cloud" {
  description = "Azure cloud environment (public or usgovernment)"
  type        = string
  default     = "public"

  validation {
    condition     = contains(["public", "usgovernment"], var.azure_cloud)
    error_message = "Azure cloud must be 'public' or 'usgovernment'."
  }
}

variable "naming_prefix" {
  description = "Prefix for resource naming (optional, uses location-environment if not set)"
  type        = string
  default     = null
}

#
# Network Configuration
#

variable "hub_address_space" {
  description = "Address space for hub virtual network (CIDR notation)"
  type        = list(string)

  validation {
    condition     = can([for cidr in var.hub_address_space : cidrhost(cidr, 0)])
    error_message = "Hub address space must be valid CIDR notation."
  }
}

variable "firewall_subnet_address_prefix" {
  description = "Address prefix for AzureFirewallSubnet (minimum /26)"
  type        = string

  validation {
    condition     = tonumber(split("/", var.firewall_subnet_address_prefix)[1]) <= 26
    error_message = "Firewall subnet must be /26 or larger."
  }
}

variable "bastion_subnet_address_prefix" {
  description = "Address prefix for AzureBastionSubnet (minimum /26)"
  type        = string

  validation {
    condition     = tonumber(split("/", var.bastion_subnet_address_prefix)[1]) <= 26
    error_message = "Bastion subnet must be /26 or larger."
  }
}

variable "gateway_subnet_address_prefix" {
  description = "Address prefix for GatewaySubnet (minimum /27)"
  type        = string

  validation {
    condition     = tonumber(split("/", var.gateway_subnet_address_prefix)[1]) <= 27
    error_message = "Gateway subnet must be /27 or larger."
  }
}

variable "management_subnet_address_prefix" {
  description = "Address prefix for management subnet (jump boxes, build agents)"
  type        = string
}

variable "shared_services_subnet_address_prefix" {
  description = "Address prefix for shared services subnet (DNS, AD DS)"
  type        = string
}

#
# Azure Firewall Configuration
#

variable "firewall_sku_tier" {
  description = "Azure Firewall SKU tier"
  type        = string
  default     = "Premium"

  validation {
    condition     = contains(["Standard", "Premium"], var.firewall_sku_tier)
    error_message = "Firewall SKU tier must be Standard or Premium."
  }
}

variable "enable_forced_tunneling" {
  description = "Enable forced tunneling for Azure Firewall"
  type        = bool
  default     = false
}

variable "custom_dns_servers" {
  description = "Custom DNS servers for Azure Firewall (null = Azure DNS)"
  type        = list(string)
  default     = null
}

variable "threat_intelligence_allowlist_ips" {
  description = "IP addresses to allowlist in threat intelligence"
  type        = list(string)
  default     = []
}

variable "threat_intelligence_allowlist_fqdns" {
  description = "FQDNs to allowlist in threat intelligence"
  type        = list(string)
  default     = []
}

variable "idps_mode" {
  description = "IDPS mode for Azure Firewall Premium (Alert, Deny, or Off)"
  type        = string
  default     = "Alert"

  validation {
    condition     = contains(["Alert", "Deny", "Off"], var.idps_mode)
    error_message = "IDPS mode must be Alert, Deny, or Off."
  }
}

variable "idps_signature_overrides" {
  description = "IDPS signature overrides"
  type = list(object({
    id    = string
    state = string
  }))
  default = []
}

variable "idps_traffic_bypass" {
  description = "IDPS traffic bypass rules"
  type = list(object({
    name                  = string
    protocol              = string
    description           = string
    destination_addresses = list(string)
    destination_ports     = list(string)
    source_addresses      = list(string)
    source_ip_groups      = list(string)
  }))
  default = []
}

variable "enable_tls_inspection" {
  description = "Enable TLS inspection for Azure Firewall Premium"
  type        = bool
  default     = false
}

variable "tls_inspection_keyvault_secret_id" {
  description = "Key Vault secret ID for TLS inspection certificate"
  type        = string
  default     = null
}

variable "custom_network_rules" {
  description = "Custom network rule collections"
  type = list(object({
    name     = string
    priority = number
    action   = string
    rules = list(object({
      name                  = string
      protocols             = list(string)
      source_addresses      = list(string)
      destination_addresses = list(string)
      destination_ports     = list(string)
      source_ip_groups      = optional(list(string))
      destination_ip_groups = optional(list(string))
    }))
  }))
  default = []
}

variable "custom_application_rules" {
  description = "Custom application rule collections"
  type = list(object({
    name     = string
    priority = number
    action   = string
    rules = list(object({
      name = string
      protocols = list(object({
        type = string
        port = number
      }))
      source_addresses      = optional(list(string))
      source_ip_groups      = optional(list(string))
      destination_fqdns     = optional(list(string))
      destination_fqdn_tags = optional(list(string))
    }))
  }))
  default = []
}

variable "dnat_rules" {
  description = "DNAT rule collections"
  type = list(object({
    name     = string
    priority = number
    rules = list(object({
      name               = string
      protocols          = list(string)
      source_addresses   = list(string)
      destination_ports  = list(string)
      translated_address = string
      translated_port    = string
    }))
  }))
  default = []
}

#
# Azure Bastion Configuration
#

variable "bastion_sku" {
  description = "Azure Bastion SKU (Basic, Standard, or Premium)"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.bastion_sku)
    error_message = "Bastion SKU must be Basic, Standard, or Premium."
  }
}

variable "bastion_copy_paste_enabled" {
  description = "Enable copy/paste for Bastion"
  type        = bool
  default     = true
}

variable "bastion_file_copy_enabled" {
  description = "Enable file copy for Bastion Premium"
  type        = bool
  default     = false
}

variable "bastion_ip_connect_enabled" {
  description = "Enable IP-based connection for Bastion Premium"
  type        = bool
  default     = false
}

variable "bastion_shareable_link_enabled" {
  description = "Enable shareable links for Bastion Premium"
  type        = bool
  default     = false
}

variable "bastion_tunneling_enabled" {
  description = "Enable native client tunneling for Bastion Premium"
  type        = bool
  default     = false
}

#
# VPN Gateway Configuration
#

variable "enable_vpn_gateway" {
  description = "Enable VPN Gateway"
  type        = bool
  default     = true
}

variable "vpn_gateway_sku" {
  description = "VPN Gateway SKU"
  type        = string
  default     = "VpnGw2AZ"

  validation {
    condition     = can(regex("^VpnGw(1|2|3|4|5)(AZ)?$", var.vpn_gateway_sku))
    error_message = "VPN Gateway SKU must be VpnGw1-5 or VpnGw1-5AZ."
  }
}

variable "vpn_gateway_active_active" {
  description = "Enable active-active VPN Gateway"
  type        = bool
  default     = false
}

variable "vpn_gateway_enable_bgp" {
  description = "Enable BGP for VPN Gateway"
  type        = bool
  default     = true
}

variable "vpn_gateway_bgp_asn" {
  description = "BGP ASN for VPN Gateway"
  type        = number
  default     = 65515

  validation {
    condition     = var.vpn_gateway_bgp_asn >= 64512 && var.vpn_gateway_bgp_asn <= 65534
    error_message = "BGP ASN must be in private range 64512-65534."
  }
}

variable "vpn_gateway_bgp_peer_weight" {
  description = "BGP peer weight"
  type        = number
  default     = 0
}

variable "vpn_gateway_bgp_apipa_addresses" {
  description = "BGP APIPA addresses for active-active configuration"
  type        = list(list(string))
  default     = []
}

#
# ExpressRoute Gateway Configuration
#

variable "enable_expressroute_gateway" {
  description = "Enable ExpressRoute Gateway"
  type        = bool
  default     = false
}

variable "expressroute_gateway_sku" {
  description = "ExpressRoute Gateway SKU"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "HighPerformance", "UltraPerformance", "ErGw1AZ", "ErGw2AZ", "ErGw3AZ"], var.expressroute_gateway_sku)
    error_message = "ExpressRoute Gateway SKU must be Standard, HighPerformance, UltraPerformance, ErGw1AZ, ErGw2AZ, or ErGw3AZ."
  }
}

#
# High Availability
#

variable "availability_zones" {
  description = "Availability zones for zone-redundant resources"
  type        = list(string)
  default     = ["1", "2", "3"]

  validation {
    condition     = alltrue([for zone in var.availability_zones : contains(["1", "2", "3"], zone)])
    error_message = "Availability zones must be 1, 2, or 3."
  }
}

variable "enable_ddos_protection" {
  description = "Enable DDoS Protection Standard (expensive)"
  type        = bool
  default     = false
}

#
# Network Monitoring
#

variable "enable_network_watcher" {
  description = "Enable Network Watcher"
  type        = bool
  default     = true
}

variable "enable_nsg_flow_logs" {
  description = "Enable NSG flow logs"
  type        = bool
  default     = true
}

variable "nsg_flow_logs_retention_days" {
  description = "Retention period for NSG flow logs"
  type        = number
  default     = 30

  validation {
    condition     = var.nsg_flow_logs_retention_days >= 0 && var.nsg_flow_logs_retention_days <= 365
    error_message = "NSG flow logs retention must be 0-365 days."
  }
}

variable "enable_traffic_analytics" {
  description = "Enable Traffic Analytics for NSG flow logs"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for diagnostics"
  type        = string
  default     = null
}

variable "log_analytics_resource_id" {
  description = "Log Analytics workspace resource ID for Traffic Analytics"
  type        = string
  default     = null
}

#
# Spoke VNet Peering
#

variable "spoke_virtual_networks" {
  description = "Map of spoke virtual networks to peer with hub"
  type = map(object({
    vnet_id             = string
    resource_group_name = string
  }))
  default = {}
}

#
# Tags
#

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
