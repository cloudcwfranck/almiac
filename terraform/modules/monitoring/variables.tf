variable "log_analytics_name" {
  description = "Name of the Log Analytics workspace"
  type        = string
}

variable "application_insights_name" {
  description = "Name of the Application Insights instance"
  type        = string
  default     = ""
}

variable "automation_account_name" {
  description = "Name of the Automation Account"
  type        = string
  default     = ""
}

variable "diagnostic_storage_name" {
  description = "Name of the diagnostic storage account"
  type        = string
  default     = ""
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# Log Analytics Configuration
variable "log_analytics_sku" {
  description = "SKU for Log Analytics workspace"
  type        = string
  default     = "PerGB2018"
}

variable "retention_in_days" {
  description = "Log retention in days"
  type        = number
  default     = 90
}

variable "daily_quota_gb" {
  description = "Daily ingestion quota in GB (-1 for unlimited)"
  type        = number
  default     = -1
}

# Solutions
variable "enable_security_solution" {
  description = "Enable Security solution"
  type        = bool
  default     = true
}

variable "enable_updates_solution" {
  description = "Enable Updates solution"
  type        = bool
  default     = true
}

variable "enable_change_tracking" {
  description = "Enable Change Tracking solution"
  type        = bool
  default     = true
}

variable "enable_vm_insights" {
  description = "Enable VM Insights solution"
  type        = bool
  default     = true
}

variable "enable_container_insights" {
  description = "Enable Container Insights solution"
  type        = bool
  default     = false
}

# Application Insights
variable "enable_application_insights" {
  description = "Enable Application Insights"
  type        = bool
  default     = false
}

variable "application_type" {
  description = "Application type for Application Insights"
  type        = string
  default     = "web"
}

# Automation Account
variable "enable_automation_account" {
  description = "Enable Automation Account"
  type        = bool
  default     = true
}

# Activity Log Diagnostics
variable "enable_activity_log_diagnostics" {
  description = "Enable Activity Log diagnostics"
  type        = bool
  default     = true
}

# Action Groups
variable "enable_action_groups" {
  description = "Enable action groups for alerts"
  type        = bool
  default     = true
}

variable "critical_alert_emails" {
  description = "Email addresses for critical alerts"
  type        = list(string)
  default     = []
}

variable "warning_alert_emails" {
  description = "Email addresses for warning alerts"
  type        = list(string)
  default     = []
}

# Diagnostic Storage
variable "enable_diagnostic_storage" {
  description = "Enable diagnostic storage account"
  type        = bool
  default     = true
}
