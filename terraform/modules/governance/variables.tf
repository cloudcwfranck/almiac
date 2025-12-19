# Required Tags
variable "required_tags" {
  description = "Required tags for all resources"
  type = object({
    Environment        = string
    CostCenter         = string
    Owner              = string
    Application        = string
    Criticality        = string
    DataClassification = string
  })

  validation {
    condition     = contains(["dev", "staging", "prod", "sandbox"], var.required_tags.Environment)
    error_message = "Environment must be one of: dev, staging, prod, sandbox."
  }

  validation {
    condition     = contains(["Low", "Medium", "High", "Mission-Critical"], var.required_tags.Criticality)
    error_message = "Criticality must be one of: Low, Medium, High, Mission-Critical."
  }

  validation {
    condition     = contains(["Public", "Internal", "Confidential", "Restricted"], var.required_tags.DataClassification)
    error_message = "DataClassification must be one of: Public, Internal, Confidential, Restricted."
  }
}

# Optional Tags
variable "optional_tags" {
  description = "Optional tags for resources"
  type        = map(string)
  default     = {}
}

# General Variables
variable "environment" {
  description = "Environment name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "subscription_name" {
  description = "Azure subscription name"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name for cost management resources"
  type        = string
}

variable "resource_group_id" {
  description = "Resource group ID for locking"
  type        = string
  default     = null
}

variable "deployment_date" {
  description = "Deployment date (YYYY-MM-DD)"
  type        = string
  default     = null
}

# Budget Configuration
variable "enable_budget" {
  description = "Enable Azure consumption budget"
  type        = bool
  default     = true
}

variable "budget_amount" {
  description = "Budget amount in USD"
  type        = number
  default     = 10000
}

variable "budget_time_grain" {
  description = "Budget time grain (Monthly, Quarterly, Annually)"
  type        = string
  default     = "Monthly"

  validation {
    condition     = contains(["Monthly", "Quarterly", "Annually"], var.budget_time_grain)
    error_message = "Budget time grain must be Monthly, Quarterly, or Annually."
  }
}

variable "budget_start_date" {
  description = "Budget start date (YYYY-MM-DDTHH:MM:SSZ)"
  type        = string
  default     = null
}

variable "budget_end_date" {
  description = "Budget end date (YYYY-MM-DDTHH:MM:SSZ)"
  type        = string
  default     = null
}

variable "budget_notification_emails" {
  description = "Email addresses for budget notifications"
  type        = list(string)
  default     = []
}

variable "budget_resource_groups" {
  description = "Resource groups to include in budget (null = all)"
  type        = list(string)
  default     = null
}

# Tag Policy
variable "enable_tag_policy" {
  description = "Enable tag governance policy"
  type        = bool
  default     = true
}

# Cost Alerts
variable "enable_cost_alerts" {
  description = "Enable cost alerting"
  type        = bool
  default     = true
}

variable "cost_alert_email" {
  description = "Email for cost alerts"
  type        = string
  default     = ""
}

# Resource Locks
variable "enable_resource_lock" {
  description = "Enable resource group lock"
  type        = bool
  default     = false
}

variable "resource_lock_level" {
  description = "Resource lock level (CanNotDelete or ReadOnly)"
  type        = string
  default     = "CanNotDelete"

  validation {
    condition     = contains(["CanNotDelete", "ReadOnly"], var.resource_lock_level)
    error_message = "Lock level must be CanNotDelete or ReadOnly."
  }
}
