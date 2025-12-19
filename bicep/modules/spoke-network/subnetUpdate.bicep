// Subnet Update Module
// Used to update subnet properties without recreating

@description('Virtual network name')
param vnetName string

@description('Subnet name')
param subnetName string

@description('Subnet address prefix')
param addressPrefix string

@description('Route table ID')
param routeTableId string

@description('Network security group ID')
param networkSecurityGroupId string

@description('Service endpoints')
param serviceEndpoints array

@description('Delegations')
param delegations array

@description('Private endpoint network policies')
param privateEndpointNetworkPolicies string

@description('Private link service network policies')
param privateLinkServiceNetworkPolicies string

// Existing VNet reference
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: vnetName
}

// Update subnet
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = {
  parent: vnet
  name: subnetName
  properties: {
    addressPrefix: addressPrefix
    routeTable: !empty(routeTableId) ? {
      id: routeTableId
    } : null
    networkSecurityGroup: !empty(networkSecurityGroupId) ? {
      id: networkSecurityGroupId
    } : null
    serviceEndpoints: serviceEndpoints
    delegations: delegations
    privateEndpointNetworkPolicies: privateEndpointNetworkPolicies
    privateLinkServiceNetworkPolicies: privateLinkServiceNetworkPolicies
  }
}

output subnetId string = subnet.id
