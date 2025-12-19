variable "workload_name" {
  description = "Name of the workload or application"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{2,50}$", var.workload_name))
    error_message = "Workload name must be 2-50 characters long and contain only letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod, sandbox)"
  type        = string
  
  validation {
    condition     = contains(["dev", "development", "stg", "staging", "prod", "production", "sbx", "sandbox"], var.environment)
    error_message = "Environment must be one of: dev, development, stg, staging, prod, production, sbx, sandbox."
  }
}

variable "location" {
  description = "Azure region where resources will be deployed"
  type        = string
}

variable "instance_number" {
  description = "Instance number for the resource (001, 002, etc.)"
  type        = number
  default     = null
  
  validation {
    condition     = var.instance_number == null || (var.instance_number >= 1 && var.instance_number <= 999)
    error_message = "Instance number must be between 1 and 999."
  }
}

variable "custom_prefix" {
  description = "Custom prefix for resource names (optional)"
  type        = string
  default     = null
}

variable "os_type" {
  description = "Operating system type for VM naming (windows or linux)"
  type        = string
  default     = "linux"
  
  validation {
    condition     = contains(["windows", "linux"], var.os_type)
    error_message = "OS type must be either 'windows' or 'linux'."
  }
}

variable "organization" {
  description = "Organization name for resource naming"
  type        = string
  default     = null
}

variable "project_code" {
  description = "Project code for resource naming"
  type        = string
  default     = null
}
