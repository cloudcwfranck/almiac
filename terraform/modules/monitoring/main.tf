# Monitoring Module - Log Analytics, Application Insights, Alerts

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = var.log_analytics_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.log_analytics_sku
  retention_in_days   = var.retention_in_days
  daily_quota_gb      = var.daily_quota_gb

  tags = var.tags
}

# Log Analytics Solutions
resource "azurerm_log_analytics_solution" "security" {
  count = var.enable_security_solution ? 1 : 0

  solution_name         = "Security"
  location              = var.location
  resource_group_name   = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.main.id
  workspace_name        = azurerm_log_analytics_workspace.main.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/Security"
  }

  tags = var.tags
}

resource "azurerm_log_analytics_solution" "updates" {
  count = var.enable_updates_solution ? 1 : 0

  solution_name         = "Updates"
  location              = var.location
  resource_group_name   = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.main.id
  workspace_name        = azurerm_log_analytics_workspace.main.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/Updates"
  }

  tags = var.tags
}

resource "azurerm_log_analytics_solution" "change_tracking" {
  count = var.enable_change_tracking ? 1 : 0

  solution_name         = "ChangeTracking"
  location              = var.location
  resource_group_name   = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.main.id
  workspace_name        = azurerm_log_analytics_workspace.main.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ChangeTracking"
  }

  tags = var.tags
}

resource "azurerm_log_analytics_solution" "vm_insights" {
  count = var.enable_vm_insights ? 1 : 0

  solution_name         = "VMInsights"
  location              = var.location
  resource_group_name   = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.main.id
  workspace_name        = azurerm_log_analytics_workspace.main.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/VMInsights"
  }

  tags = var.tags
}

resource "azurerm_log_analytics_solution" "container_insights" {
  count = var.enable_container_insights ? 1 : 0

  solution_name         = "ContainerInsights"
  location              = var.location
  resource_group_name   = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.main.id
  workspace_name        = azurerm_log_analytics_workspace.main.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }

  tags = var.tags
}

# Application Insights
resource "azurerm_application_insights" "main" {
  count = var.enable_application_insights ? 1 : 0

  name                = var.application_insights_name
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = var.application_type
  retention_in_days   = var.retention_in_days

  tags = var.tags
}

# Automation Account
resource "azurerm_automation_account" "main" {
  count = var.enable_automation_account ? 1 : 0

  name                = var.automation_account_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "Basic"

  tags = var.tags
}

# Link Automation Account to Log Analytics
resource "azurerm_log_analytics_linked_service" "automation" {
  count = var.enable_automation_account ? 1 : 0

  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  read_access_id      = azurerm_automation_account.main[0].id
}

# Diagnostic Settings for Activity Log
resource "azurerm_monitor_diagnostic_setting" "subscription" {
  count = var.enable_activity_log_diagnostics ? 1 : 0

  name                       = "diag-activity-log-${var.environment}"
  target_resource_id         = "/subscriptions/${var.subscription_id}"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "Administrative"
  }

  enabled_log {
    category = "Security"
  }

  enabled_log {
    category = "ServiceHealth"
  }

  enabled_log {
    category = "Alert"
  }

  enabled_log {
    category = "Recommendation"
  }

  enabled_log {
    category = "Policy"
  }

  enabled_log {
    category = "Autoscale"
  }

  enabled_log {
    category = "ResourceHealth"
  }
}

# Action Groups for Alerts
resource "azurerm_monitor_action_group" "critical" {
  count = var.enable_action_groups ? 1 : 0

  name                = "ag-critical-${var.environment}"
  resource_group_name = var.resource_group_name
  short_name          = "critical"

  dynamic "email_receiver" {
    for_each = var.critical_alert_emails
    content {
      name          = "Email-${email_receiver.key}"
      email_address = email_receiver.value
    }
  }

  tags = var.tags
}

resource "azurerm_monitor_action_group" "warning" {
  count = var.enable_action_groups ? 1 : 0

  name                = "ag-warning-${var.environment}"
  resource_group_name = var.resource_group_name
  short_name          = "warning"

  dynamic "email_receiver" {
    for_each = var.warning_alert_emails
    content {
      name          = "Email-${email_receiver.key}"
      email_address = email_receiver.value
    }
  }

  tags = var.tags
}

# Diagnostic Storage Account
resource "azurerm_storage_account" "diagnostics" {
  count = var.enable_diagnostic_storage ? 1 : 0

  name                     = var.diagnostic_storage_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    delete_retention_policy {
      days = 30
    }
  }

  tags = var.tags
}
