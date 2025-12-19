// Production Management Subscription
// Deploys monitoring and management resources

targetScope = 'subscription'

@description('Azure region for resources')
param location string = 'eastus'

@description('Environment name')
param environment string = 'prod'

@description('Tags for all resources')
param tags object = {
  Environment: 'prod'
  CostCenter: 'IT-OPS-001'
  Owner: 'platform-team@company.com'
  Application: 'management'
  Criticality: 'Mission-Critical'
  DataClassification: 'Internal'
  ManagedBy: 'Bicep'
}

// Variables
var resourceGroupName = 'rg-management-${environment}-${location}-001'
var workspaceName = 'law-management-${environment}-${location}-001'

// Resource Group
resource managementRg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// Log Analytics Workspace
module logAnalytics '../modules/monitoring/log-analytics.bicep' = {
  name: 'log-analytics-deployment'
  scope: managementRg
  params: {
    workspaceName: workspaceName
    location: location
    retentionInDays: 90
    enableSecuritySolution: true
    enableUpdatesSolution: true
    enableChangeTracking: true
    tags: tags
  }
}

// Outputs
output workspaceId string = logAnalytics.outputs.workspaceId
output resourceGroupName string = managementRg.name
