// Hub Virtual Network Module

@description('Virtual network name')
param vnetName string

@description('Azure region')
param location string

@description('Virtual network address prefix')
param addressPrefix string

@description('Firewall subnet address prefix (minimum /26)')
param firewallSubnetPrefix string

@description('Bastion subnet address prefix (minimum /26)')
param bastionSubnetPrefix string

@description('Gateway subnet address prefix (minimum /27)')
param gatewaySubnetPrefix string

@description('Management subnet address prefix')
param managementSubnetPrefix string

@description('Shared services subnet address prefix')
param sharedServicesSubnetPrefix string

@description('Enable DDoS Protection')
param enableDDoSProtection bool = false

@description('DDoS Protection Plan ID')
param ddosProtectionPlanId string = ''

@description('DNS servers')
param dnsServers array = []

@description('Tags')
param tags object

// Hub Virtual Network
resource hubVnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    dhcpOptions: !empty(dnsServers) ? {
      dnsServers: dnsServers
    } : null
    enableDdosProtection: enableDDoSProtection
    ddosProtectionPlan: enableDDoSProtection ? {
      id: ddosProtectionPlanId
    } : null
  }
}

// Azure Firewall Subnet (name must be exactly 'AzureFirewallSubnet')
resource firewallSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = {
  parent: hubVnet
  name: 'AzureFirewallSubnet'
  properties: {
    addressPrefix: firewallSubnetPrefix
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Disabled'
  }
}

// Azure Bastion Subnet (name must be exactly 'AzureBastionSubnet')
resource bastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = {
  parent: hubVnet
  name: 'AzureBastionSubnet'
  properties: {
    addressPrefix: bastionSubnetPrefix
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Disabled'
  }
  dependsOn: [
    firewallSubnet
  ]
}

// Gateway Subnet (name must be exactly 'GatewaySubnet')
resource gatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = {
  parent: hubVnet
  name: 'GatewaySubnet'
  properties: {
    addressPrefix: gatewaySubnetPrefix
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Disabled'
  }
  dependsOn: [
    bastionSubnet
  ]
}

// Management Subnet
resource managementSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = {
  parent: hubVnet
  name: 'snet-management'
  properties: {
    addressPrefix: managementSubnetPrefix
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
  dependsOn: [
    gatewaySubnet
  ]
}

// Shared Services Subnet
resource sharedServicesSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = {
  parent: hubVnet
  name: 'snet-shared-services'
  properties: {
    addressPrefix: sharedServicesSubnetPrefix
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
  dependsOn: [
    managementSubnet
  ]
}

// Network Security Groups

// Management NSG
resource managementNsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: '${vnetName}-management-nsg'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Allow-RDP-From-Bastion'
        properties: {
          description: 'Allow RDP from Bastion subnet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: bastionSubnetPrefix
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow-SSH-From-Bastion'
        properties: {
          description: 'Allow SSH from Bastion subnet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: bastionSubnetPrefix
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'Deny-All-Inbound'
        properties: {
          description: 'Deny all other inbound traffic'
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
    ]
  }
}

// Shared Services NSG
resource sharedServicesNsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: '${vnetName}-shared-services-nsg'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Allow-DNS-From-VNet'
        properties: {
          description: 'Allow DNS from VNet'
          protocol: 'Udp'
          sourcePortRange: '*'
          destinationPortRange: '53'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow-LDAP-From-VNet'
        properties: {
          description: 'Allow LDAP/LDAPS from VNet'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRanges: [
            '389'
            '636'
            '3268'
            '3269'
          ]
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow-Kerberos-From-VNet'
        properties: {
          description: 'Allow Kerberos from VNet'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '88'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
    ]
  }
}

// NSG Associations
resource managementNsgAssociation 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = {
  parent: hubVnet
  name: 'snet-management'
  properties: {
    addressPrefix: managementSubnetPrefix
    networkSecurityGroup: {
      id: managementNsg.id
    }
  }
  dependsOn: [
    sharedServicesSubnet
  ]
}

resource sharedServicesNsgAssociation 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = {
  parent: hubVnet
  name: 'snet-shared-services'
  properties: {
    addressPrefix: sharedServicesSubnetPrefix
    networkSecurityGroup: {
      id: sharedServicesNsg.id
    }
  }
  dependsOn: [
    managementNsgAssociation
  ]
}

// Outputs
output vnetId string = hubVnet.id
output vnetName string = hubVnet.name
output firewallSubnetId string = firewallSubnet.id
output bastionSubnetId string = bastionSubnet.id
output gatewaySubnetId string = gatewaySubnet.id
output managementSubnetId string = managementSubnet.id
output sharedServicesSubnetId string = sharedServicesSubnet.id
output managementNsgId string = managementNsg.id
output sharedServicesNsgId string = sharedServicesNsg.id
