// Private DNS Zones Module

@description('Virtual network ID to link DNS zones')
param vnetId string

@description('Virtual network name')
param vnetName string

@description('Azure cloud environment')
@allowed([
  'public'
  'usgovernment'
])
param azureCloud string = 'public'

@description('Tags')
param tags object

// Define DNS zones based on cloud environment
var dnsZones = azureCloud == 'usgovernment' ? [
  'privatelink.blob.core.usgovcloudapi.net'
  'privatelink.file.core.usgovcloudapi.net'
  'privatelink.queue.core.usgovcloudapi.net'
  'privatelink.table.core.usgovcloudapi.net'
  'privatelink.vaultcore.usgovcloudapi.net'
  'privatelink.database.usgovcloudapi.net'
  'privatelink.azurecr.us'
  'privatelink.azurewebsites.us'
  'privatelink.documents.azure.us'
] : [
  'privatelink.blob.core.windows.net'
  'privatelink.file.core.windows.net'
  'privatelink.queue.core.windows.net'
  'privatelink.table.core.windows.net'
  'privatelink.vaultcore.azure.net'
  'privatelink.database.windows.net'
  'privatelink.azurecr.io'
  'privatelink.azurewebsites.net'
  'privatelink.documents.azure.com'
]

// Create Private DNS Zones
resource privateDnsZones 'Microsoft.Network/privateDnsZones@2020-06-01' = [for zone in dnsZones: {
  name: zone
  location: 'global'
  tags: tags
}]

// Link DNS Zones to VNet
resource vnetLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for (zone, i) in dnsZones: {
  parent: privateDnsZones[i]
  name: '${vnetName}-link'
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}]

// Outputs
output dnsZoneIds array = [for (zone, i) in dnsZones: privateDnsZones[i].id]
output dnsZoneNames array = [for (zone, i) in dnsZones: privateDnsZones[i].name]
output dnsZoneMap object = reduce(map(range(0, length(dnsZones)), i => {
    key: split(dnsZones[i], '.')[1] // Extract service name (blob, file, etc.)
    value: privateDnsZones[i].id
  }), {}, (cur, next) => union(cur, {
    '${next.key}': next.value
  }))
