// Hub Network Main Orchestrator
// Deploys complete hub network infrastructure

targetScope = 'subscription'

@description('Resource group name for hub network')
param resourceGroupName string

@description('Azure region')
@allowed([
  'eastus'
  'eastus2'
  'westus'
  'westus2'
  'centralus'
  'usgovvirginia'
  'usgovtexas'
  'usgovarizona'
  'westeurope'
  'northeurope'
])
param location string

@description('Environment')
@allowed([
  'dev'
  'stg'
  'prd'
])
param environment string

@description('Azure cloud environment')
@allowed([
  'public'
  'usgovernment'
])
param azureCloud string = 'public'

@description('Hub virtual network address prefix')
param hubAddressPrefix string

@description('Firewall subnet prefix (minimum /26)')
param firewallSubnetPrefix string

@description('Bastion subnet prefix (minimum /26)')
param bastionSubnetPrefix string

@description('Gateway subnet prefix (minimum /27)')
param gatewaySubnetPrefix string

@description('Management subnet prefix')
param managementSubnetPrefix string

@description('Shared services subnet prefix')
param sharedServicesSubnetPrefix string

@description('Firewall SKU tier')
@allowed([
  'Standard'
  'Premium'
])
param firewallTier string = 'Premium'

@description('Firewall IDPS mode')
@allowed([
  'Alert'
  'Deny'
  'Off'
])
param firewallIdpsMode string = 'Alert'

@description('Enable TLS inspection (Premium only)')
param enableTlsInspection bool = false

@description('Key Vault secret ID for TLS certificate')
param tlsKeyVaultSecretId string = ''

@description('Custom DNS servers')
param customDnsServers array = []

@description('Bastion SKU')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param bastionSku string = 'Standard'

@description('Enable VPN Gateway')
param enableVpnGateway bool = true

@description('VPN Gateway SKU')
@allowed([
  'VpnGw1'
  'VpnGw2'
  'VpnGw3'
  'VpnGw4'
  'VpnGw5'
  'VpnGw1AZ'
  'VpnGw2AZ'
  'VpnGw3AZ'
])
param vpnGatewaySku string = 'VpnGw2AZ'

@description('Enable VPN active-active')
param vpnActiveActive bool = false

@description('Enable VPN BGP')
param vpnEnableBgp bool = true

@description('VPN BGP ASN')
param vpnBgpAsn int = 65515

@description('Enable ExpressRoute Gateway')
param enableExpressRouteGateway bool = false

@description('ExpressRoute Gateway SKU')
@allowed([
  'Standard'
  'HighPerformance'
  'UltraPerformance'
  'ErGw1AZ'
  'ErGw2AZ'
  'ErGw3AZ'
])
param expressRouteGatewaySku string = 'Standard'

@description('Enable DDoS Protection')
param enableDDoSProtection bool = false

@description('Availability zones')
param availabilityZones array = [
  '1'
  '2'
  '3'
]

@description('Log Analytics workspace resource ID for diagnostics')
param logAnalyticsWorkspaceId string = ''

@description('Tags')
param tags object = {}

// Computed values
var regionAbbr = {
  eastus: 'eus'
  eastus2: 'eus2'
  westus: 'wus'
  westus2: 'wus2'
  centralus: 'cus'
  usgovvirginia: 'ugv'
  usgovtexas: 'ugt'
  usgovarizona: 'uga'
  westeurope: 'weu'
  northeurope: 'neu'
}

var envAbbr = {
  dev: 'dev'
  stg: 'stg'
  prd: 'prd'
}

var namingPrefix = '${regionAbbr[location]}-${envAbbr[environment]}'
var vnetName = 'vnet-hub-${namingPrefix}'
var firewallName = 'afw-${namingPrefix}'
var bastionName = 'bas-${namingPrefix}'
var gatewayNamePrefix = 'gw-${namingPrefix}'

var defaultTags = {
  Environment: environment
  ManagedBy: 'Bicep'
  Location: location
  Workload: 'hub'
}

var allTags = union(defaultTags, tags)

// Firewall policy configuration
var firewallPolicyConfig = {
  threatIntelMode: 'Alert'
  idpsMode: firewallIdpsMode
  dnsProxyEnabled: true
  customDnsServers: customDnsServers
  tlsInspectionEnabled: enableTlsInspection
  tlsKeyVaultSecretId: tlsKeyVaultSecretId
}

// Resource Group
resource hubResourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
  tags: allTags
}

// DDoS Protection Plan (if enabled)
module ddosProtection './ddosProtection.bicep' = if (enableDDoSProtection) {
  scope: hubResourceGroup
  name: 'ddos-deployment'
  params: {
    ddosPlanName: 'ddos-${namingPrefix}'
    location: location
    tags: allTags
  }
}

// Hub Virtual Network
module hubVnet './vnet.bicep' = {
  scope: hubResourceGroup
  name: 'vnet-deployment'
  params: {
    vnetName: vnetName
    location: location
    addressPrefix: hubAddressPrefix
    firewallSubnetPrefix: firewallSubnetPrefix
    bastionSubnetPrefix: bastionSubnetPrefix
    gatewaySubnetPrefix: gatewaySubnetPrefix
    managementSubnetPrefix: managementSubnetPrefix
    sharedServicesSubnetPrefix: sharedServicesSubnetPrefix
    enableDDoSProtection: enableDDoSProtection
    ddosProtectionPlanId: enableDDoSProtection ? ddosProtection.outputs.ddosPlanId : ''
    dnsServers: customDnsServers
    tags: allTags
  }
}

// Azure Firewall
module firewall './firewall.bicep' = {
  scope: hubResourceGroup
  name: 'firewall-deployment'
  params: {
    firewallName: firewallName
    location: location
    firewallTier: firewallTier
    firewallSubnetId: hubVnet.outputs.firewallSubnetId
    availabilityZones: availabilityZones
    policyConfig: firewallPolicyConfig
    enableForcedTunneling: false
    tags: allTags
  }
}

// Azure Bastion
module bastion './bastion.bicep' = {
  scope: hubResourceGroup
  name: 'bastion-deployment'
  params: {
    bastionName: bastionName
    location: location
    bastionSku: bastionSku
    bastionSubnetId: hubVnet.outputs.bastionSubnetId
    enableCopyPaste: true
    enableFileCopy: bastionSku == 'Premium'
    enableIpConnect: bastionSku == 'Premium'
    enableShareableLink: false
    enableTunneling: bastionSku == 'Premium'
    tags: allTags
  }
}

// VPN/ExpressRoute Gateway
module gateway './gateway.bicep' = if (enableVpnGateway || enableExpressRouteGateway) {
  scope: hubResourceGroup
  name: 'gateway-deployment'
  params: {
    gatewayNamePrefix: gatewayNamePrefix
    location: location
    gatewaySubnetId: hubVnet.outputs.gatewaySubnetId
    enableVpnGateway: enableVpnGateway
    vpnGatewaySku: vpnGatewaySku
    vpnActiveActive: vpnActiveActive
    vpnEnableBgp: vpnEnableBgp
    vpnBgpAsn: vpnBgpAsn
    enableExpressRouteGateway: enableExpressRouteGateway
    expressRouteGatewaySku: expressRouteGatewaySku
    availabilityZones: availabilityZones
    tags: allTags
  }
  dependsOn: [
    hubVnet
  ]
}

// Private DNS Zones
module privateDns './privateDns.bicep' = {
  scope: hubResourceGroup
  name: 'privateDns-deployment'
  params: {
    vnetId: hubVnet.outputs.vnetId
    vnetName: hubVnet.outputs.vnetName
    azureCloud: azureCloud
    tags: allTags
  }
}

// Diagnostic Settings (if Log Analytics workspace provided)
module diagnostics './diagnostics.bicep' = if (!empty(logAnalyticsWorkspaceId)) {
  scope: hubResourceGroup
  name: 'diagnostics-deployment'
  params: {
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    vnetId: hubVnet.outputs.vnetId
    firewallId: firewall.outputs.firewallId
    bastionId: bastion.outputs.bastionId
    vpnGatewayId: enableVpnGateway ? gateway.outputs.vpnGatewayId : ''
    managementNsgId: hubVnet.outputs.managementNsgId
    sharedServicesNsgId: hubVnet.outputs.sharedServicesNsgId
  }
}

// Outputs
output resourceGroupName string = hubResourceGroup.name
output vnetId string = hubVnet.outputs.vnetId
output vnetName string = hubVnet.outputs.vnetName
output firewallPrivateIp string = firewall.outputs.firewallPrivateIp
output firewallPublicIp string = firewall.outputs.firewallPublicIp
output firewallId string = firewall.outputs.firewallId
output bastionId string = bastion.outputs.bastionId
output bastionDnsName string = bastion.outputs.bastionDnsName
output vpnGatewayId string = enableVpnGateway ? gateway.outputs.vpnGatewayId : ''
output expressRouteGatewayId string = enableExpressRouteGateway ? gateway.outputs.expressRouteGatewayId : ''
output privateDnsZoneIds array = privateDns.outputs.dnsZoneIds
output privateDnsZoneMap object = privateDns.outputs.dnsZoneMap
output subnetIds object = {
  firewall: hubVnet.outputs.firewallSubnetId
  bastion: hubVnet.outputs.bastionSubnetId
  gateway: hubVnet.outputs.gatewaySubnetId
  management: hubVnet.outputs.managementSubnetId
  sharedServices: hubVnet.outputs.sharedServicesSubnetId
}
