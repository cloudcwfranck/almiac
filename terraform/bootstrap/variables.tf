variable "resource_group_name" {
  description = "Name of the resource group for Terraform state"
  type        = string
  default     = "rg-terraform-state"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "location_abbreviation" {
  description = "Location abbreviation"
  type        = string
  default     = "eus"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "storage_account_prefix" {
  description = "Prefix for storage account name"
  type        = string
  default     = "sttfstate"
}

variable "container_name" {
  description = "Name of the storage container"
  type        = string
  default     = "tfstate"
}

variable "storage_replication_type" {
  description = "Storage replication type"
  type        = string
  default     = "GRS"
}

variable "azure_environment" {
  description = "Azure environment (public or usgovernment)"
  type        = string
  default     = "public"
}

variable "enable_public_access" {
  description = "Enable public network access to storage"
  type        = bool
  default     = false
}

variable "allowed_ip_addresses" {
  description = "List of allowed IP addresses"
  type        = list(string)
  default     = []
}

variable "enable_diagnostics" {
  description = "Enable diagnostic logging"
  type        = bool
  default     = true
}

variable "create_key_vault" {
  description = "Create Key Vault for secrets"
  type        = bool
  default     = false
}

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
  default     = ""
}

variable "cost_center" {
  description = "Cost center tag"
  type        = string
  default     = "IT-OPS"
}
