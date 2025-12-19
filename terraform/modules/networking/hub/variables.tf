variable "hub_vnet_name" {
  description = "Name of the hub virtual network"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "hub_address_space" {
  description = "Address space for hub VNet"
  type        = list(string)
}

variable "firewall_subnet_prefix" {
  description = "Address prefix for firewall subnet"
  type        = string
  default     = ""
}

variable "bastion_subnet_prefix" {
  description = "Address prefix for bastion subnet"
  type        = string
  default     = ""
}

variable "gateway_subnet_prefix" {
  description = "Address prefix for gateway subnet"
  type        = string
  default     = ""
}

variable "management_subnet_prefix" {
  description = "Address prefix for management subnet"
  type        = string
}

variable "enable_firewall" {
  description = "Enable Azure Firewall"
  type        = bool
  default     = true
}

variable "firewall_name" {
  description = "Name of the Azure Firewall"
  type        = string
  default     = ""
}

variable "firewall_sku_name" {
  description = "SKU name for Azure Firewall"
  type        = string
  default     = "AZFW_VNet"
}

variable "firewall_sku_tier" {
  description = "SKU tier for Azure Firewall"
  type        = string
  default     = "Standard"
}

variable "firewall_policy_id" {
  description = "ID of existing firewall policy"
  type        = string
  default     = null
}

variable "threat_intelligence_mode" {
  description = "Threat intelligence mode"
  type        = string
  default     = "Alert"
}

variable "enable_bastion" {
  description = "Enable Azure Bastion"
  type        = bool
  default     = true
}

variable "bastion_name" {
  description = "Name of the Bastion host"
  type        = string
  default     = ""
}

variable "bastion_sku" {
  description = "SKU for Bastion"
  type        = string
  default     = "Standard"
}

variable "enable_vpn_gateway" {
  description = "Enable VPN Gateway"
  type        = bool
  default     = false
}

variable "vpn_gateway_name" {
  description = "Name of the VPN Gateway"
  type        = string
  default     = ""
}

variable "vpn_type" {
  description = "VPN type"
  type        = string
  default     = "RouteBased"
}

variable "vpn_gateway_sku" {
  description = "SKU for VPN Gateway"
  type        = string
  default     = "VpnGw2AZ"
}

variable "vpn_active_active" {
  description = "Enable active-active VPN"
  type        = bool
  default     = false
}

variable "enable_bgp" {
  description = "Enable BGP"
  type        = bool
  default     = false
}

variable "bgp_asn" {
  description = "BGP ASN"
  type        = number
  default     = 65515
}

variable "enable_expressroute_gateway" {
  description = "Enable ExpressRoute Gateway"
  type        = bool
  default     = false
}

variable "expressroute_gateway_name" {
  description = "Name of the ExpressRoute Gateway"
  type        = string
  default     = ""
}

variable "expressroute_gateway_sku" {
  description = "SKU for ExpressRoute Gateway"
  type        = string
  default     = "Standard"
}

variable "enable_ddos_protection" {
  description = "Enable DDoS protection"
  type        = bool
  default     = false
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for diagnostics"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
