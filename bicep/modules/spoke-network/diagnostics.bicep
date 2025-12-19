// Diagnostic Settings Module for Spoke Network

@description('Log Analytics workspace ID')
param logAnalyticsWorkspaceId string

@description('VNet ID')
param vnetId string

@description('NSG IDs object')
param nsgIds object

// VNet name from ID
var vnetName = last(split(vnetId, '/'))

// VNet Diagnostic Settings
resource vnetDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: resourceId('Microsoft.Network/virtualNetworks', vnetName)
  name: 'diag-${vnetName}'
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

// NSG Diagnostic Settings
resource nsgDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = [for nsgId in items(nsgIds): {
  scope: resourceId('Microsoft.Network/networkSecurityGroups', last(split(nsgId.value, '/')))
  name: 'diag-${last(split(nsgId.value, '/'))}'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'NetworkSecurityGroupEvent'
        enabled: true
      }
      {
        category: 'NetworkSecurityGroupRuleCounter'
        enabled: true
      }
    ]
  }
}]

// Outputs
output vnetDiagnosticsId string = vnetDiagnostics.id
