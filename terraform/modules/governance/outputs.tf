# Tag outputs are in main.tf

output "budget_id" {
  description = "ID of the consumption budget"
  value       = var.enable_budget ? azurerm_consumption_budget_subscription.budget[0].id : null
}

output "tag_policy_assignment_id" {
  description = "ID of the tag governance policy assignment"
  value       = var.enable_tag_policy ? azurerm_subscription_policy_assignment.tag_governance[0].id : null
}

output "cost_action_group_id" {
  description = "ID of the cost alerts action group"
  value       = var.enable_cost_alerts ? azurerm_monitor_action_group.cost_alerts[0].id : null
}

output "resource_lock_id" {
  description = "ID of the resource group lock"
  value       = var.enable_resource_lock ? azurerm_management_lock.resource_group_lock[0].id : null
}
