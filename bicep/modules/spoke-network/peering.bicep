// VNet Peering Module

@description('Local virtual network name')
param localVnetName string

@description('Local resource group name')
param localResourceGroupName string

@description('Remote virtual network ID')
param remoteVnetId string

@description('Peering name')
param peeringName string

@description('Allow virtual network access')
param allowVirtualNetworkAccess bool = true

@description('Allow forwarded traffic')
param allowForwardedTraffic bool = true

@description('Allow gateway transit')
param allowGatewayTransit bool = false

@description('Use remote gateways')
param useRemoteGateways bool = false

// Existing local VNet reference
resource localVnet 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: localVnetName
}

// VNet Peering
resource peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-05-01' = {
  parent: localVnet
  name: peeringName
  properties: {
    allowVirtualNetworkAccess: allowVirtualNetworkAccess
    allowForwardedTraffic: allowForwardedTraffic
    allowGatewayTransit: allowGatewayTransit
    useRemoteGateways: useRemoteGateways
    remoteVirtualNetwork: {
      id: remoteVnetId
    }
  }
}

// Outputs
output peeringId string = peering.id
output peeringName string = peering.name
output peeringState string = peering.properties.peeringState
