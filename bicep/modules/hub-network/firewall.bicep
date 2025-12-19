// Azure Firewall Module

@description('Firewall name')
param firewallName string

@description('Azure region')
param location string

@description('Firewall SKU tier')
@allowed([
  'Standard'
  'Premium'
])
param firewallTier string = 'Premium'

@description('Firewall subnet ID')
param firewallSubnetId string

@description('Availability zones')
param availabilityZones array = [
  '1'
  '2'
  '3'
]

@description('Firewall policy configuration')
param policyConfig object

@description('Enable forced tunneling')
param enableForcedTunneling bool = false

@description('Tags')
param tags object

// Firewall Public IP
resource firewallPublicIp 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: '${firewallName}-pip'
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

// Firewall Management Public IP (for forced tunneling)
resource firewallMgmtPublicIp 'Microsoft.Network/publicIPAddresses@2023-05-01' = if (enableForcedTunneling) {
  name: '${firewallName}-mgmt-pip'
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

// Firewall Policy
resource firewallPolicy 'Microsoft.Network/firewallPolicies@2023-05-01' = {
  name: '${firewallName}-policy'
  location: location
  tags: tags
  properties: {
    sku: {
      tier: firewallTier
    }
    threatIntelMode: policyConfig.threatIntelMode
    dnsSettings: {
      enableProxy: policyConfig.dnsProxyEnabled
      servers: policyConfig.?customDnsServers ?? []
    }
    intrusionDetection: firewallTier == 'Premium' ? {
      mode: policyConfig.idpsMode
      configuration: {
        signatureOverrides: []
        bypassTrafficSettings: []
      }
    } : null
    threatIntelWhitelist: {
      ipAddresses: []
      fqdns: []
    }
    transportSecurity: firewallTier == 'Premium' && policyConfig.tlsInspectionEnabled ? {
      certificateAuthority: {
        keyVaultSecretId: policyConfig.tlsKeyVaultSecretId
        name: 'tls-inspection-ca'
      }
    } : null
  }
}

// Network Rule Collection Group
resource networkRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-05-01' = {
  parent: firewallPolicy
  name: 'NetworkRuleCollectionGroup'
  properties: {
    priority: 100
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'AllowAzureServices'
        priority: 100
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'AllowAzureCloud'
            ipProtocols: [
              'TCP'
              'UDP'
            ]
            sourceAddresses: [
              '*'
            ]
            destinationAddresses: [
              'AzureCloud'
            ]
            destinationPorts: [
              '443'
              '80'
            ]
          }
          {
            ruleType: 'NetworkRule'
            name: 'AllowAzureMonitor'
            ipProtocols: [
              'TCP'
            ]
            sourceAddresses: [
              '*'
            ]
            destinationAddresses: [
              'AzureMonitor'
            ]
            destinationPorts: [
              '443'
            ]
          }
        ]
      }
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'AllowTimeSync'
        priority: 110
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'AllowNTP'
            ipProtocols: [
              'UDP'
            ]
            sourceAddresses: [
              '*'
            ]
            destinationAddresses: [
              '*'
            ]
            destinationPorts: [
              '123'
            ]
          }
        ]
      }
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'AllowDNS'
        priority: 120
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'AllowDNSOutbound'
            ipProtocols: [
              'UDP'
              'TCP'
            ]
            sourceAddresses: [
              '*'
            ]
            destinationAddresses: policyConfig.?customDnsServers ?? [
              '168.63.129.16'
            ]
            destinationPorts: [
              '53'
            ]
          }
        ]
      }
    ]
  }
}

// Application Rule Collection Group
resource applicationRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-05-01' = {
  parent: firewallPolicy
  name: 'ApplicationRuleCollectionGroup'
  properties: {
    priority: 200
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'AllowWindowsUpdates'
        priority: 100
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'ApplicationRule'
            name: 'WindowsUpdate'
            protocols: [
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            sourceAddresses: [
              '*'
            ]
            targetFqdns: [
              '*.windowsupdate.microsoft.com'
              '*.update.microsoft.com'
              '*.windowsupdate.com'
              '*.download.windowsupdate.com'
              '*.download.microsoft.com'
              '*.dl.delivery.mp.microsoft.com'
              '*.prod.do.dsp.mp.microsoft.com'
            ]
          }
        ]
      }
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'AllowMicrosoftServices'
        priority: 110
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'ApplicationRule'
            name: 'AzureServices'
            protocols: [
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            sourceAddresses: [
              '*'
            ]
            targetFqdns: [
              '*.azure.com'
              '*.microsoft.com'
              '*.msftauth.net'
              '*.windows.net'
            ]
          }
        ]
      }
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'AllowLinuxUpdates'
        priority: 120
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'ApplicationRule'
            name: 'UbuntuUpdates'
            protocols: [
              {
                protocolType: 'Http'
                port: 80
              }
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            sourceAddresses: [
              '*'
            ]
            targetFqdns: [
              '*.ubuntu.com'
              '*.canonical.com'
              'security.ubuntu.com'
              'archive.ubuntu.com'
            ]
          }
        ]
      }
    ]
  }
  dependsOn: [
    networkRuleCollectionGroup
  ]
}

// Azure Firewall
resource firewall 'Microsoft.Network/azureFirewalls@2023-05-01' = {
  name: firewallName
  location: location
  tags: tags
  zones: availabilityZones
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: firewallTier
    }
    firewallPolicy: {
      id: firewallPolicy.id
    }
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: firewallSubnetId
          }
          publicIPAddress: {
            id: firewallPublicIp.id
          }
        }
      }
    ]
    managementIpConfiguration: enableForcedTunneling ? {
      name: 'mgmtIpConfig'
      properties: {
        subnet: {
          id: firewallSubnetId
        }
        publicIPAddress: {
          id: firewallMgmtPublicIp.id
        }
      }
    } : null
  }
}

// Outputs
output firewallId string = firewall.id
output firewallName string = firewall.name
output firewallPublicIp string = firewallPublicIp.properties.ipAddress
output firewallPrivateIp string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
output firewallPolicyId string = firewallPolicy.id
