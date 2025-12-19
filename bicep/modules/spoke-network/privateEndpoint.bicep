// Private Endpoint Module

@description('Private endpoint name')
param privateEndpointName string

@description('Azure region')
param location string

@description('Subnet ID for private endpoint')
param subnetId string

@description('Private link service ID')
param privateLinkServiceId string

@description('Group IDs for the private link service')
param groupIds array

@description('Private DNS zone IDs')
param privateDnsZoneIds array = []

@description('Tags')
param tags object

// Private Endpoint
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: privateEndpointName
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: privateLinkServiceId
          groupIds: groupIds
        }
      }
    ]
  }
}

// Private DNS Zone Group (if DNS zones provided)
resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = if (!empty(privateDnsZoneIds)) {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [for (zoneId, i) in privateDnsZoneIds: {
      name: 'config${i}'
      properties: {
        privateDnsZoneId: zoneId
      }
    }]
  }
}

// Outputs
output privateEndpointId string = privateEndpoint.id
output privateEndpointName string = privateEndpoint.name
output privateIpAddress string = privateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]
