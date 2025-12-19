# Governance Module - Tagging, Cost Management, and Compliance

# Standard Tags
locals {
  # Combine required and optional tags
  standard_tags = merge(
    var.required_tags,
    var.optional_tags,
    {
      ManagedBy        = "Terraform"
      LastModified     = timestamp()
      DeploymentDate   = var.deployment_date != null ? var.deployment_date : formatdate("YYYY-MM-DD", timestamp())
      TerraformWorkspace = terraform.workspace
    }
  )

  # Remove any null values
  tags = { for k, v in local.standard_tags : k => v if v != null }
}

# Output tags for use in resources
output "tags" {
  description = "Standard tags for all resources"
  value       = local.tags
}

output "required_tags" {
  description = "Required tags that must be present"
  value = {
    Environment        = var.required_tags.Environment
    CostCenter         = var.required_tags.CostCenter
    Owner              = var.required_tags.Owner
    Application        = var.required_tags.Application
    Criticality        = var.required_tags.Criticality
    DataClassification = var.required_tags.DataClassification
  }
}

# Cost Management - Budget
resource "azurerm_consumption_budget_subscription" "budget" {
  count = var.enable_budget ? 1 : 0

  name            = "budget-${var.subscription_name}"
  subscription_id = var.subscription_id

  amount     = var.budget_amount
  time_grain = var.budget_time_grain

  time_period {
    start_date = var.budget_start_date != null ? var.budget_start_date : formatdate("YYYY-MM-01'T'00:00:00Z", timestamp())
    end_date   = var.budget_end_date
  }

  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThan"
    threshold_type = "Actual"

    contact_emails = var.budget_notification_emails
    contact_roles  = ["Owner", "Contributor"]
  }

  notification {
    enabled        = true
    threshold      = 90
    operator       = "GreaterThan"
    threshold_type = "Actual"

    contact_emails = var.budget_notification_emails
    contact_roles  = ["Owner", "Contributor"]
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    threshold_type = "Actual"

    contact_emails = var.budget_notification_emails
    contact_roles  = ["Owner", "Contributor"]
  }

  notification {
    enabled        = true
    threshold      = 110
    operator       = "GreaterThan"
    threshold_type = "Forecasted"

    contact_emails = var.budget_notification_emails
    contact_roles  = ["Owner", "Contributor"]
  }

  filter {
    dimension {
      name = "ResourceGroupName"
      values = var.budget_resource_groups != null ? var.budget_resource_groups : []
    }
  }
}

# Cost Allocation Tags Policy
resource "azurerm_subscription_policy_assignment" "tag_governance" {
  count = var.enable_tag_policy ? 1 : 0

  name                 = "enforce-required-tags"
  subscription_id      = var.subscription_id
  policy_definition_id = azurerm_policy_set_definition.tag_governance[0].id
  description          = "Enforces required tags on all resources"
  display_name         = "Enforce Required Tags"

  identity {
    type = "SystemAssigned"
  }

  location = var.location
}

# Tag Policy Definition Set
resource "azurerm_policy_set_definition" "tag_governance" {
  count = var.enable_tag_policy ? 1 : 0

  name         = "tag-governance-initiative"
  policy_type  = "Custom"
  display_name = "Tag Governance Initiative"
  description  = "Enforces required tags and tag inheritance"

  metadata = jsonencode({
    category = "Tags"
    version  = "1.0.0"
  })

  # Require tags on resource groups
  policy_definition_reference {
    policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025"
    parameter_values = jsonencode({
      tagName = {
        value = "Environment"
      }
    })
    reference_id = "requireEnvironmentTag"
  }

  policy_definition_reference {
    policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025"
    parameter_values = jsonencode({
      tagName = {
        value = "CostCenter"
      }
    })
    reference_id = "requireCostCenterTag"
  }

  policy_definition_reference {
    policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025"
    parameter_values = jsonencode({
      tagName = {
        value = "Owner"
      }
    })
    reference_id = "requireOwnerTag"
  }

  policy_definition_reference {
    policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025"
    parameter_values = jsonencode({
      tagName = {
        value = "Application"
      }
    })
    reference_id = "requireApplicationTag"
  }

  # Inherit tags from resource group
  policy_definition_reference {
    policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/cd3aa116-8754-49c9-a813-ad46512ece54"
    parameter_values = jsonencode({
      tagName = {
        value = "Environment"
      }
    })
    reference_id = "inheritEnvironmentTag"
  }

  policy_definition_reference {
    policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/cd3aa116-8754-49c9-a813-ad46512ece54"
    parameter_values = jsonencode({
      tagName = {
        value = "CostCenter"
      }
    })
    reference_id = "inheritCostCenterTag"
  }
}

# Azure Advisor Recommendations
resource "azurerm_monitor_action_group" "cost_alerts" {
  count = var.enable_cost_alerts ? 1 : 0

  name                = "ag-cost-alerts-${var.environment}"
  resource_group_name = var.resource_group_name
  short_name          = "costalert"

  email_receiver {
    name          = "CostAlerts"
    email_address = var.cost_alert_email
  }

  tags = local.tags
}

# Resource Group Lock (optional)
resource "azurerm_management_lock" "resource_group_lock" {
  count = var.enable_resource_lock ? 1 : 0

  name       = "lock-${var.resource_group_name}"
  scope      = var.resource_group_id
  lock_level = var.resource_lock_level
  notes      = "Locked by Terraform to prevent accidental deletion"
}
