// Spoke Network Module
// Landing zone spoke network with automatic hub peering

targetScope = 'subscription'

@description('Resource group name for spoke network')
param resourceGroupName string

@description('Azure region')
param location string

@description('Environment')
@allowed([
  'dev'
  'stg'
  'prd'
])
param environment string

@description('Workload name')
@minLength(2)
@maxLength(20)
param workloadName string

@description('Spoke virtual network address prefix')
param spokeAddressPrefix string

@description('Subnet configurations')
param subnetConfigurations array

@description('Hub virtual network ID')
param hubVNetId string

@description('Hub resource group name')
param hubResourceGroupName string

@description('Firewall private IP for routing')
param firewallPrivateIp string = ''

@description('Use remote gateways from hub')
param useRemoteGateways bool = true

@description('Hub allows gateway transit')
param hubAllowGatewayTransit bool = true

@description('Private DNS zone IDs from hub')
param privateDnsZoneIds array = []

@description('Private endpoint configurations')
param privateEndpointConfigurations array = []

@description('Enable NSG flow logs')
param enableNsgFlowLogs bool = true

@description('NSG flow logs retention days')
@minValue(0)
@maxValue(365)
param flowLogsRetentionDays int = 30

@description('Network Watcher name')
param networkWatcherName string = ''

@description('Network Watcher resource group')
param networkWatcherResourceGroup string = ''

@description('Flow logs storage account ID')
param flowLogsStorageAccountId string = ''

@description('Log Analytics workspace ID for diagnostics')
param logAnalyticsWorkspaceId string = ''

@description('Tags')
param tags object = {}

// Computed values
var regionAbbr = {
  eastus: 'eus'
  eastus2: 'eus2'
  westus: 'wus'
  westus2: 'wus2'
  centralus: 'cus'
  usgovvirginia: 'ugv'
  usgovtexas: 'ugt'
  usgovarizona: 'uga'
  westeurope: 'weu'
  northeurope: 'neu'
}

var envAbbr = {
  dev: 'dev'
  stg: 'stg'
  prd: 'prd'
}

var namingPrefix = '${workloadName}-${regionAbbr[location]}-${envAbbr[environment]}'
var vnetName = 'vnet-${namingPrefix}'
var routeTableName = 'rt-${namingPrefix}'
var hubVnetName = last(split(hubVNetId, '/'))

var defaultTags = {
  Environment: environment
  ManagedBy: 'Bicep'
  Location: location
  Workload: workloadName
}

var allTags = union(defaultTags, tags)

// Resource Group
resource spokeResourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
  tags: allTags
}

// Spoke Virtual Network
module spokeVnet './vnet.bicep' = {
  scope: spokeResourceGroup
  name: 'spoke-vnet-deployment'
  params: {
    vnetName: vnetName
    location: location
    addressPrefix: spokeAddressPrefix
    subnetConfigurations: subnetConfigurations
    tags: allTags
  }
}

// Route Table
module routeTable './routeTable.bicep' = if (!empty(firewallPrivateIp)) {
  scope: spokeResourceGroup
  name: 'routeTable-deployment'
  params: {
    routeTableName: routeTableName
    location: location
    firewallPrivateIp: firewallPrivateIp
    tags: allTags
  }
}

// Associate Route Tables with Subnets
module routeTableAssociations './routeTableAssociation.bicep' = [for (subnet, i) in subnetConfigurations: if (!empty(firewallPrivateIp) && (subnet.?associateRouteTable ?? true)) {
  scope: spokeResourceGroup
  name: 'route-assoc-${subnet.name}-${i}'
  params: {
    vnetName: vnetName
    subnetName: subnet.name
    routeTableId: routeTable.outputs.routeTableId
  }
  dependsOn: [
    spokeVnet
    routeTable
  ]
}]

// VNet Peering - Spoke to Hub
module peeringSpokeToHub './peering.bicep' = {
  scope: resourceGroup(split(hubVNetId, '/')[2], split(hubVNetId, '/')[4])
  name: 'peering-spoke-to-hub-deployment'
  params: {
    localVnetName: vnetName
    localResourceGroupName: resourceGroupName
    remoteVnetId: hubVNetId
    peeringName: 'peer-${vnetName}-to-hub'
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: useRemoteGateways
  }
  dependsOn: [
    spokeVnet
  ]
}

// VNet Peering - Hub to Spoke
module peeringHubToSpoke './peering.bicep' = {
  scope: resourceGroup(hubResourceGroupName)
  name: 'peering-hub-to-spoke-deployment'
  params: {
    localVnetName: hubVnetName
    localResourceGroupName: hubResourceGroupName
    remoteVnetId: spokeVnet.outputs.vnetId
    peeringName: 'peer-hub-to-${vnetName}'
    allowForwardedTraffic: true
    allowGatewayTransit: hubAllowGatewayTransit
    useRemoteGateways: false
  }
  dependsOn: [
    spokeVnet
  ]
}

// Private Endpoints
module privateEndpoints './privateEndpoint.bicep' = [for (pe, i) in privateEndpointConfigurations: {
  scope: spokeResourceGroup
  name: 'pe-${pe.name}-deployment'
  params: {
    privateEndpointName: '${pe.name}-pe'
    location: location
    subnetId: spokeVnet.outputs.subnetIds[pe.subnetName]
    privateLinkServiceId: pe.privateLinkServiceId
    groupIds: pe.groupIds
    privateDnsZoneIds: pe.?privateDnsZoneIds ?? []
    tags: allTags
  }
  dependsOn: [
    spokeVnet
  ]
}]

// NSG Flow Logs
module flowLogs './flowLogs.bicep' = [for (subnet, i) in subnetConfigurations: if (enableNsgFlowLogs && !empty(networkWatcherName) && !empty(flowLogsStorageAccountId)) {
  scope: resourceGroup(networkWatcherResourceGroup)
  name: 'flowlog-${subnet.name}-${i}'
  params: {
    networkWatcherName: networkWatcherName
    nsgId: spokeVnet.outputs.nsgIds[subnet.name]
    storageAccountId: flowLogsStorageAccountId
    retentionDays: flowLogsRetentionDays
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    location: location
    tags: allTags
  }
  dependsOn: [
    spokeVnet
  ]
}]

// Diagnostic Settings
module diagnostics './diagnostics.bicep' = if (!empty(logAnalyticsWorkspaceId)) {
  scope: spokeResourceGroup
  name: 'diagnostics-deployment'
  params: {
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    vnetId: spokeVnet.outputs.vnetId
    nsgIds: spokeVnet.outputs.nsgIds
  }
  dependsOn: [
    spokeVnet
  ]
}

// Outputs
output resourceGroupName string = spokeResourceGroup.name
output vnetId string = spokeVnet.outputs.vnetId
output vnetName string = spokeVnet.outputs.vnetName
output subnetIds object = spokeVnet.outputs.subnetIds
output nsgIds object = spokeVnet.outputs.nsgIds
output routeTableId string = !empty(firewallPrivateIp) ? routeTable.outputs.routeTableId : ''
output privateEndpointIds array = [for (pe, i) in privateEndpointConfigurations: privateEndpoints[i].outputs.privateEndpointId]
output privateEndpointPrivateIps array = [for (pe, i) in privateEndpointConfigurations: privateEndpoints[i].outputs.privateIpAddress]
