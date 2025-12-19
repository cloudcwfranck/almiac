// Log Analytics Workspace Module
// Creates Log Analytics workspace with monitoring solutions

@description('Name of the Log Analytics workspace')
param workspaceName string

@description('Azure region for resources')
param location string = resourceGroup().location

@description('SKU for Log Analytics')
@allowed([
  'PerGB2018'
  'CapacityReservation'
])
param sku string = 'PerGB2018'

@description('Retention period in days')
@minValue(30)
@maxValue(730)
param retentionInDays int = 90

@description('Daily ingestion quota in GB')
param dailyQuotaGb int = -1

@description('Enable Security solution')
param enableSecuritySolution bool = true

@description('Enable Updates solution')
param enableUpdatesSolution bool = true

@description('Enable Change Tracking solution')
param enableChangeTracking bool = true

@description('Tags for resources')
param tags object = {}

// Log Analytics Workspace
resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: sku
    }
    retentionInDays: retentionInDays
    workspaceCapping: {
      dailyQuotaGb: dailyQuotaGb
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Security Solution
resource securitySolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = if (enableSecuritySolution) {
  name: 'Security(${workspace.name})'
  location: location
  tags: tags
  properties: {
    workspaceResourceId: workspace.id
  }
  plan: {
    name: 'Security(${workspace.name})'
    publisher: 'Microsoft'
    product: 'OMSGallery/Security'
    promotionCode: ''
  }
}

// Updates Solution
resource updatesSolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = if (enableUpdatesSolution) {
  name: 'Updates(${workspace.name})'
  location: location
  tags: tags
  properties: {
    workspaceResourceId: workspace.id
  }
  plan: {
    name: 'Updates(${workspace.name})'
    publisher: 'Microsoft'
    product: 'OMSGallery/Updates'
    promotionCode: ''
  }
}

// Change Tracking Solution
resource changeTrackingSolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = if (enableChangeTracking) {
  name: 'ChangeTracking(${workspace.name})'
  location: location
  tags: tags
  properties: {
    workspaceResourceId: workspace.id
  }
  plan: {
    name: 'ChangeTracking(${workspace.name})'
    publisher: 'Microsoft'
    product: 'OMSGallery/ChangeTracking'
    promotionCode: ''
  }
}

// Outputs
output workspaceId string = workspace.id
output workspaceName string = workspace.name
output customerId string = workspace.properties.customerId
