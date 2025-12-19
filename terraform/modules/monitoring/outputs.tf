output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.name
}

output "log_analytics_workspace_key" {
  description = "Primary key of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.primary_shared_key
  sensitive   = true
}

output "log_analytics_workspace_location" {
  description = "Location of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.location
}

output "application_insights_id" {
  description = "ID of Application Insights"
  value       = var.enable_application_insights ? azurerm_application_insights.main[0].id : null
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key for Application Insights"
  value       = var.enable_application_insights ? azurerm_application_insights.main[0].instrumentation_key : null
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Connection string for Application Insights"
  value       = var.enable_application_insights ? azurerm_application_insights.main[0].connection_string : null
  sensitive   = true
}

output "automation_account_id" {
  description = "ID of the Automation Account"
  value       = var.enable_automation_account ? azurerm_automation_account.main[0].id : null
}

output "automation_account_name" {
  description = "Name of the Automation Account"
  value       = var.enable_automation_account ? azurerm_automation_account.main[0].name : null
}

output "critical_action_group_id" {
  description = "ID of the critical alerts action group"
  value       = var.enable_action_groups ? azurerm_monitor_action_group.critical[0].id : null
}

output "warning_action_group_id" {
  description = "ID of the warning alerts action group"
  value       = var.enable_action_groups ? azurerm_monitor_action_group.warning[0].id : null
}

output "diagnostic_storage_account_id" {
  description = "ID of the diagnostic storage account"
  value       = var.enable_diagnostic_storage ? azurerm_storage_account.diagnostics[0].id : null
}

output "diagnostic_storage_account_name" {
  description = "Name of the diagnostic storage account"
  value       = var.enable_diagnostic_storage ? azurerm_storage_account.diagnostics[0].name : null
}
