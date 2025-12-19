// Spoke Virtual Network Module

@description('Virtual network name')
param vnetName string

@description('Azure region')
param location string

@description('Address prefix for the VNet')
param addressPrefix string

@description('Subnet configurations')
param subnetConfigurations array

@description('Tags')
param tags object

// Virtual Network
resource spokeVnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    enableDdosProtection: false
  }
}

// Network Security Groups for each subnet
resource nsgs 'Microsoft.Network/networkSecurityGroups@2023-05-01' = [for subnet in subnetConfigurations: {
  name: 'nsg-${subnet.name}'
  location: location
  tags: tags
  properties: {
    securityRules: concat(
      // Default deny all inbound
      [
        {
          name: 'DenyAllInbound'
          properties: {
            description: 'Deny all inbound traffic by default'
            protocol: '*'
            sourcePortRange: '*'
            destinationPortRange: '*'
            sourceAddressPrefix: '*'
            destinationAddressPrefix: '*'
            access: 'Deny'
            priority: 4096
            direction: 'Inbound'
          }
        }
      ],
      // Custom rules if provided
      subnet.?securityRules ?? []
    )
  }
}]

// Subnets
resource subnets 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = [for (subnet, i) in subnetConfigurations: {
  parent: spokeVnet
  name: subnet.name
  properties: {
    addressPrefix: subnet.addressPrefix
    networkSecurityGroup: {
      id: nsgs[i].id
    }
    serviceEndpoints: subnet.?serviceEndpoints ?? []
    delegations: subnet.?delegations ?? []
    privateEndpointNetworkPolicies: subnet.?privateEndpointNetworkPolicies ?? 'Disabled'
    privateLinkServiceNetworkPolicies: subnet.?privateLinkServiceNetworkPolicies ?? 'Enabled'
  }
}]

// Outputs
output vnetId string = spokeVnet.id
output vnetName string = spokeVnet.name
output subnetIds object = {
  for (subnet, i) in subnetConfigurations: subnet.name => subnets[i].id
}
output nsgIds object = {
  for (subnet, i) in subnetConfigurations: subnet.name => nsgs[i].id
}
