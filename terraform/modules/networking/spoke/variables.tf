variable "spoke_vnet_name" {
  description = "Name of the spoke virtual network"
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

variable "spoke_address_space" {
  description = "Address space for spoke VNet"
  type        = list(string)
}

variable "workload_subnets" {
  description = "Map of workload subnets"
  type = map(object({
    address_prefix    = string
    service_endpoints = optional(list(string), [])
    delegation = optional(object({
      name         = string
      service_name = string
      actions      = optional(list(string), [])
    }))
  }))
}

variable "hub_vnet_id" {
  description = "ID of the hub virtual network"
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

variable "use_remote_gateways" {
  description = "Use remote gateways in hub"
  type        = bool
  default     = false
}

variable "hub_allow_gateway_transit" {
  description = "Allow gateway transit from hub"
  type        = bool
  default     = true
}

variable "enable_route_table" {
  description = "Enable route table"
  type        = bool
  default     = true
}

variable "disable_bgp_route_propagation" {
  description = "Disable BGP route propagation"
  type        = bool
  default     = false
}

variable "firewall_private_ip" {
  description = "Private IP of the firewall"
  type        = string
  default     = null
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
