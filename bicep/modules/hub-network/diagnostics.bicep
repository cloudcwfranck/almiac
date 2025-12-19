// Diagnostic Settings Module

@description('Log Analytics workspace ID')
param logAnalyticsWorkspaceId string

@description('VNet ID')
param vnetId string

@description('Firewall ID')
param firewallId string

@description('Bastion ID')
param bastionId string

@description('VPN Gateway ID')
param vpnGatewayId string

@description('Management NSG ID')
param managementNsgId string

@description('Shared Services NSG ID')
param sharedServicesNsgId string

// VNet Diagnostic Settings
resource vnetDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: resourceId('Microsoft.Network/virtualNetworks', last(split(vnetId, '/')))
  name: 'diag-vnet'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'VMProtectionAlerts'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// Firewall Diagnostic Settings
resource firewallDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: resourceId('Microsoft.Network/azureFirewalls', last(split(firewallId, '/')))
  name: 'diag-firewall'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'AzureFirewallApplicationRule'
        enabled: true
      }
      {
        category: 'AzureFirewallNetworkRule'
        enabled: true
      }
      {
        category: 'AzureFirewallDnsProxy'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// Bastion Diagnostic Settings
resource bastionDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: resourceId('Microsoft.Network/bastionHosts', last(split(bastionId, '/')))
  name: 'diag-bastion'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'BastionAuditLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// VPN Gateway Diagnostic Settings (if exists)
resource vpnDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(vpnGatewayId)) {
  scope: resourceId('Microsoft.Network/virtualNetworkGateways', last(split(vpnGatewayId, '/')))
  name: 'diag-vpn'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'GatewayDiagnosticLog'
        enabled: true
      }
      {
        category: 'TunnelDiagnosticLog'
        enabled: true
      }
      {
        category: 'RouteDiagnosticLog'
        enabled: true
      }
      {
        category: 'IKEDiagnosticLog'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}
