# Spoke Network Module Variables

#
# Basic Configuration
#

variable "resource_group_name" {
  description = "Name of the resource group for spoke network resources"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "sandbox"], var.environment)
    error_message = "Environment must be dev, staging, prod, or sandbox."
  }
}

variable "workload_name" {
  description = "Name of the workload or application"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{2,20}$", var.workload_name))
    error_message = "Workload name must be 2-20 characters, lowercase alphanumeric and hyphens only."
  }
}

variable "naming_prefix" {
  description = "Prefix for resource naming (optional, uses workload-location-environment if not set)"
  type        = string
  default     = null
}

#
# Network Configuration
#

variable "spoke_address_space" {
  description = "Address space for spoke virtual network (CIDR notation)"
  type        = list(string)

  validation {
    condition     = can([for cidr in var.spoke_address_space : cidrhost(cidr, 0)])
    error_message = "Spoke address space must be valid CIDR notation."
  }
}

variable "subnets" {
  description = "Map of subnets to create in the spoke VNet"
  type = map(object({
    address_prefix    = string
    service_endpoints = optional(list(string), [])
    delegation = optional(object({
      name         = string
      service_name = string
      actions      = optional(list(string), [])
    }))
    security_rules = optional(list(object({
      name                         = string
      priority                     = number
      direction                    = string
      access                       = string
      protocol                     = string
      source_port_range            = optional(string)
      source_port_ranges           = optional(list(string))
      destination_port_range       = optional(string)
      destination_port_ranges      = optional(list(string))
      source_address_prefix        = optional(string)
      source_address_prefixes      = optional(list(string))
      destination_address_prefix   = optional(string)
      destination_address_prefixes = optional(list(string))
      description                  = optional(string)
    })), [])
    private_endpoint_network_policies_enabled     = optional(bool, true)
    private_link_service_network_policies_enabled = optional(bool, true)
    associate_route_table                         = optional(bool, true)
  }))

  validation {
    condition     = length(var.subnets) > 0
    error_message = "At least one subnet must be defined."
  }
}

#
# Hub Network Configuration
#

variable "hub_vnet_id" {
  description = "ID of the hub virtual network to peer with"
  type        = string
}

variable "hub_vnet_name" {
  description = "Name of the hub virtual network"
  type        = string
}

variable "hub_resource_group_name" {
  description = "Name of the hub resource group"
  type        = string
}

variable "hub_firewall_private_ip" {
  description = "Private IP address of the hub firewall for routing"
  type        = string
  default     = null
}

variable "use_remote_gateways" {
  description = "Use remote VPN/ExpressRoute gateways from hub"
  type        = bool
  default     = true
}

variable "hub_allow_gateway_transit" {
  description = "Allow gateway transit from hub"
  type        = bool
  default     = true
}

#
# Routing Configuration
#

variable "disable_bgp_route_propagation" {
  description = "Disable BGP route propagation on route table"
  type        = bool
  default     = false
}

variable "custom_routes" {
  description = "Custom routes for the spoke route table"
  type = list(object({
    name                   = string
    address_prefix         = string
    next_hop_type          = string
    next_hop_in_ip_address = optional(string)
  }))
  default = []
}

#
# Private Endpoints
#

variable "private_endpoints" {
  description = "Map of private endpoints to create"
  type = map(object({
    subnet_name                    = string
    private_connection_resource_id = string
    subresource_names              = list(string)
    is_manual_connection           = optional(bool, false)
    request_message                = optional(string)
    private_dns_zone_ids           = optional(list(string))
  }))
  default = {}
}

#
# Network Monitoring
#

variable "enable_nsg_flow_logs" {
  description = "Enable NSG flow logs for all subnets"
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

variable "network_watcher_name" {
  description = "Name of the Network Watcher (from hub)"
  type        = string
  default     = null
}

variable "network_watcher_resource_group_name" {
  description = "Resource group name of the Network Watcher"
  type        = string
  default     = null
}

variable "flow_logs_storage_account_id" {
  description = "Storage account ID for NSG flow logs (from hub)"
  type        = string
  default     = null
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
# Tags
#

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
