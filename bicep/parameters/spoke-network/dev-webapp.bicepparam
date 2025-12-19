// Spoke Network Parameters - Web Application (Development)
using '../../modules/spoke-network/main.bicep'

param resourceGroupName = 'rg-webapp-eus-dev'
param location = 'eastus'
param environment = 'dev'
param workloadName = 'webapp'

// Network Configuration
param spokeAddressPrefix = '10.1.0.0/16'
param subnetConfigurations = [
  {
    name: 'frontend'
    addressPrefix: '10.1.0.0/24'
    serviceEndpoints: [
      {
        service: 'Microsoft.Web'
      }
      {
        service: 'Microsoft.KeyVault'
      }
    ]
    securityRules: [
      {
        name: 'AllowHttpsInbound'
        properties: {
          description: 'Allow HTTPS from internet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowAppGwHealthProbe'
        properties: {
          description: 'Allow Application Gateway health probe'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '65200-65535'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
    ]
  }
  {
    name: 'backend'
    addressPrefix: '10.1.1.0/24'
    serviceEndpoints: [
      {
        service: 'Microsoft.Sql'
      }
      {
        service: 'Microsoft.Storage'
      }
    ]
    securityRules: [
      {
        name: 'AllowFrontendTraffic'
        properties: {
          description: 'Allow traffic from frontend subnet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: [
            '80'
            '443'
            '8080'
          ]
          sourceAddressPrefix: '10.1.0.0/24'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
  {
    name: 'data'
    addressPrefix: '10.1.2.0/24'
    privateEndpointNetworkPolicies: 'Disabled'
    securityRules: [
      {
        name: 'AllowBackendTraffic'
        properties: {
          description: 'Allow traffic from backend subnet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: [
            '1433'
            '5432'
          ]
          sourceAddressPrefix: '10.1.1.0/24'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
]

// Hub Configuration
param hubVNetId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-hub-eus-dev/providers/Microsoft.Network/virtualNetworks/vnet-hub-eus-dev'
param hubResourceGroupName = 'rg-hub-eus-dev'
param firewallPrivateIp = '10.0.0.4'
param useRemoteGateways = true
param hubAllowGatewayTransit = true

// Private DNS Zones
param privateDnsZoneIds = [
  '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-hub-eus-dev/providers/Microsoft.Network/privateDnsZones/privatelink.database.windows.net'
  '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-hub-eus-dev/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net'
]

// Private Endpoints
param privateEndpointConfigurations = [
  {
    name: 'sql-server'
    subnetName: 'data'
    privateLinkServiceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-webapp-eus-dev/providers/Microsoft.Sql/servers/sql-webapp-dev'
    groupIds: [
      'sqlServer'
    ]
    privateDnsZoneIds: [
      '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-hub-eus-dev/providers/Microsoft.Network/privateDnsZones/privatelink.database.windows.net'
    ]
  }
]

// Flow Logs
param enableNsgFlowLogs = true
param flowLogsRetentionDays = 7
param networkWatcherName = 'NetworkWatcher_eastus'
param networkWatcherResourceGroup = 'NetworkWatcherRG'
param flowLogsStorageAccountId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-monitoring-eus-dev/providers/Microsoft.Storage/storageAccounts/stflowlogsdev'
param logAnalyticsWorkspaceId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-monitoring-eus-dev/providers/Microsoft.OperationalInsights/workspaces/law-eus-dev'

// Tags
param tags = {
  CostCenter: 'IT-Development'
  Owner: 'WebTeam'
  Project: 'WebApp'
  Workload: 'webapp'
  Criticality: 'Low'
}
