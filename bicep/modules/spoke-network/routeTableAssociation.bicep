// Route Table Association Module

@description('Virtual network name')
param vnetName string

@description('Subnet name')
param subnetName string

@description('Route table ID')
param routeTableId string

// Existing VNet reference
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: vnetName
}

// Existing subnet reference
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {
  parent: vnet
  name: subnetName
}

// Update subnet with route table
module subnetUpdate './subnetUpdate.bicep' = {
  name: 'update-${subnetName}-route-table'
  params: {
    vnetName: vnetName
    subnetName: subnetName
    addressPrefix: subnet.properties.addressPrefix
    routeTableId: routeTableId
    networkSecurityGroupId: subnet.properties.?networkSecurityGroup.?id ?? ''
    serviceEndpoints: subnet.properties.?serviceEndpoints ?? []
    delegations: subnet.properties.?delegations ?? []
    privateEndpointNetworkPolicies: subnet.properties.?privateEndpointNetworkPolicies ?? 'Disabled'
    privateLinkServiceNetworkPolicies: subnet.properties.?privateLinkServiceNetworkPolicies ?? 'Enabled'
  }
}
