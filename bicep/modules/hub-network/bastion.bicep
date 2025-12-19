// Azure Bastion Module

@description('Bastion host name')
param bastionName string

@description('Azure region')
param location string

@description('Bastion SKU')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param bastionSku string = 'Standard'

@description('Bastion subnet ID')
param bastionSubnetId string

@description('Enable copy/paste')
param enableCopyPaste bool = true

@description('Enable file copy (Premium only)')
param enableFileCopy bool = false

@description('Enable IP connect (Premium only)')
param enableIpConnect bool = false

@description('Enable shareable link (Premium only)')
param enableShareableLink bool = false

@description('Enable tunneling (Premium only)')
param enableTunneling bool = false

@description('Tags')
param tags object

// Bastion Public IP
resource bastionPublicIp 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: '${bastionName}-pip'
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

// Azure Bastion Host
resource bastionHost 'Microsoft.Network/bastionHosts@2023-05-01' = {
  name: bastionName
  location: location
  tags: tags
  sku: {
    name: bastionSku
  }
  properties: {
    enableTunneling: bastionSku == 'Premium' ? enableTunneling : false
    enableFileCopy: bastionSku == 'Premium' ? enableFileCopy : false
    enableIpConnect: bastionSku == 'Premium' ? enableIpConnect : false
    enableShareableLink: bastionSku == 'Premium' ? enableShareableLink : false
    disableCopyPaste: !enableCopyPaste
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: bastionSubnetId
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
output bastionId string = bastionHost.id
output bastionName string = bastionHost.name
output bastionDnsName string = bastionHost.properties.dnsName
output bastionPublicIp string = bastionPublicIp.properties.ipAddress
