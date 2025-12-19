// Spoke Network Parameters - Web Application (Production)
using '../../modules/spoke-network/main.bicep'

param resourceGroupName = 'rg-webapp-eus-prd'
param location = 'eastus'
param environment = 'prd'
param workloadName = 'webapp'

// Network Configuration
param spokeAddressPrefix = '10.101.0.0/16'
param subnetConfigurations = [
  {
    name: 'frontend'
    addressPrefix: '10.101.0.0/24'
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
    addressPrefix: '10.101.1.0/24'
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
          sourceAddressPrefix: '10.101.0.0/24'
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
    addressPrefix: '10.101.2.0/24'
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
          sourceAddressPrefix: '10.101.1.0/24'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
  {
    name: 'aks'
    addressPrefix: '10.101.10.0/22'
    delegations: [
      {
        name: 'aks-delegation'
        properties: {
          serviceName: 'Microsoft.ContainerService/managedClusters'
        }
      }
    ]
    associateRouteTable: false
    securityRules: []
  }
]

// Hub Configuration
param hubVNetId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-hub-eus-prd/providers/Microsoft.Network/virtualNetworks/vnet-hub-eus-prd'
param hubResourceGroupName = 'rg-hub-eus-prd'
param firewallPrivateIp = '10.100.0.4'
param useRemoteGateways = true
param hubAllowGatewayTransit = true

// Private DNS Zones
param privateDnsZoneIds = [
  '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-hub-eus-prd/providers/Microsoft.Network/privateDnsZones/privatelink.database.windows.net'
  '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-hub-eus-prd/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net'
  '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-hub-eus-prd/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net'
]

// Private Endpoints
param privateEndpointConfigurations = [
  {
    name: 'sql-server'
    subnetName: 'data'
    privateLinkServiceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-webapp-eus-prd/providers/Microsoft.Sql/servers/sql-webapp-prd'
    groupIds: [
      'sqlServer'
    ]
    privateDnsZoneIds: [
      '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-hub-eus-prd/providers/Microsoft.Network/privateDnsZones/privatelink.database.windows.net'
    ]
  }
  {
    name: 'storage-account'
    subnetName: 'data'
    privateLinkServiceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-webapp-eus-prd/providers/Microsoft.Storage/storageAccounts/stwebappprd'
    groupIds: [
      'blob'
    ]
    privateDnsZoneIds: [
      '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-hub-eus-prd/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net'
    ]
  }
]

// Flow Logs
param enableNsgFlowLogs = true
param flowLogsRetentionDays = 90
param networkWatcherName = 'NetworkWatcher_eastus'
param networkWatcherResourceGroup = 'NetworkWatcherRG'
param flowLogsStorageAccountId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-monitoring-eus-prd/providers/Microsoft.Storage/storageAccounts/stflowlogsprd'
param logAnalyticsWorkspaceId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-monitoring-eus-prd/providers/Microsoft.OperationalInsights/workspaces/law-eus-prd'

// Tags
param tags = {
  CostCenter: 'IT-Production'
  Owner: 'WebTeam'
  Project: 'WebApp'
  Workload: 'webapp'
  Criticality: 'Critical'
  Compliance: 'CIS-Azure-1.4.0'
  DataClassification: 'Confidential'
}
