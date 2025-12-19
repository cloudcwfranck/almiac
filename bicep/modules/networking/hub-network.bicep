// Hub Network Module
// Creates hub virtual network with firewall, bastion, and gateway

@description('Name of the hub virtual network')
param hubVnetName string

@description('Azure region for resources')
param location string = resourceGroup().location

@description('Address space for hub VNet')
param hubAddressSpace array = ['10.0.0.0/16']

@description('Enable Azure Firewall')
param enableFirewall bool = true

@description('Firewall SKU tier')
@allowed([
  'Standard'
  'Premium'
])
param firewallSkuTier string = 'Standard'

@description('Enable Azure Bastion')
param enableBastion bool = true

@description('Enable VPN Gateway')
param enableVpnGateway bool = false

@description('Availability zones')
param availabilityZones array = ['1', '2', '3']

@description('Tags for resources')
param tags object = {}

// Hub Virtual Network
resource hubVnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: hubVnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: hubAddressSpace
    }
  }
}

// Azure Firewall Subnet
resource firewallSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' = if (enableFirewall) {
  parent: hubVnet
  name: 'AzureFirewallSubnet'
  properties: {
    addressPrefix: '10.0.1.0/24'
  }
}

// Bastion Subnet
resource bastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' = if (enableBastion) {
  parent: hubVnet
  name: 'AzureBastionSubnet'
  properties: {
    addressPrefix: '10.0.2.0/24'
  }
  dependsOn: [
    firewallSubnet
  ]
}

// Gateway Subnet
resource gatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' = if (enableVpnGateway) {
  parent: hubVnet
  name: 'GatewaySubnet'
  properties: {
    addressPrefix: '10.0.3.0/24'
  }
  dependsOn: [
    bastionSubnet
  ]
}

// Management Subnet
resource managementSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' = {
  parent: hubVnet
  name: 'snet-management'
  properties: {
    addressPrefix: '10.0.4.0/24'
  }
  dependsOn: [
    gatewaySubnet
  ]
}

// Azure Firewall Public IP
resource firewallPublicIp 'Microsoft.Network/publicIPAddresses@2023-04-01' = if (enableFirewall) {
  name: '${hubVnetName}-afw-pip'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  zones: availabilityZones
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

// Azure Firewall Policy
resource firewallPolicy 'Microsoft.Network/firewallPolicies@2023-04-01' = if (enableFirewall) {
  name: '${hubVnetName}-afw-policy'
  location: location
  tags: tags
  properties: {
    sku: {
      tier: firewallSkuTier
    }
    threatIntelMode: 'Alert'
    dnsSettings: {
      enableProxy: true
    }
  }
}

// Azure Firewall
resource firewall 'Microsoft.Network/azureFirewalls@2023-04-01' = if (enableFirewall) {
  name: '${hubVnetName}-afw'
  location: location
  tags: tags
  zones: availabilityZones
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: firewallSkuTier
    }
    firewallPolicy: {
      id: firewallPolicy.id
    }
    ipConfigurations: [
      {
        name: 'configuration'
        properties: {
          subnet: {
            id: firewallSubnet.id
          }
          publicIPAddress: {
            id: firewallPublicIp.id
          }
        }
      }
    ]
  }
}

// Bastion Public IP
resource bastionPublicIp 'Microsoft.Network/publicIPAddresses@2023-04-01' = if (enableBastion) {
  name: '${hubVnetName}-bas-pip'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

// Azure Bastion
resource bastion 'Microsoft.Network/bastionHosts@2023-04-01' = if (enableBastion) {
  name: '${hubVnetName}-bas'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'configuration'
        properties: {
          subnet: {
            id: bastionSubnet.id
          }
          publicIPAddress: {
            id: bastionPublicIp.id
          }
        }
      }
    ]
  }
}

// Outputs
output hubVnetId string = hubVnet.id
output hubVnetName string = hubVnet.name
output firewallPrivateIp string = enableFirewall ? firewall.properties.ipConfigurations[0].properties.privateIPAddress : ''
