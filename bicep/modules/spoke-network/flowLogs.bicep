// NSG Flow Logs Module

@description('Network Watcher name')
param networkWatcherName string

@description('NSG ID')
param nsgId string

@description('Storage account ID for flow logs')
param storageAccountId string

@description('Retention days')
param retentionDays int = 30

@description('Log Analytics workspace ID')
param logAnalyticsWorkspaceId string = ''

@description('Azure region')
param location string

@description('Tags')
param tags object

// NSG name from ID
var nsgName = last(split(nsgId, '/'))

// Existing Network Watcher reference
resource networkWatcher 'Microsoft.Network/networkWatchers@2023-05-01' existing = {
  name: networkWatcherName
}

// Flow Log
resource flowLog 'Microsoft.Network/networkWatchers/flowLogs@2023-05-01' = {
  parent: networkWatcher
  name: 'flowlog-${nsgName}'
  location: location
  tags: tags
  properties: {
    targetResourceId: nsgId
    storageId: storageAccountId
    enabled: true
    retentionPolicy: {
      days: retentionDays
      enabled: retentionDays > 0
    }
    format: {
      type: 'JSON'
      version: 2
    }
    flowAnalyticsConfiguration: !empty(logAnalyticsWorkspaceId) ? {
      networkWatcherFlowAnalyticsConfiguration: {
        enabled: true
        workspaceId: reference(logAnalyticsWorkspaceId, '2022-10-01').customerId
        workspaceRegion: location
        workspaceResourceId: logAnalyticsWorkspaceId
        trafficAnalyticsInterval: 60
      }
    } : null
  }
}

// Outputs
output flowLogId string = flowLog.id
output flowLogName string = flowLog.name
