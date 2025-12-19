// User-defined types for hub network module

@description('Subnet configuration type')
type subnetConfig = {
  @description('Name of the subnet')
  name: string
  
  @description('Address prefix in CIDR notation')
  addressPrefix: string
  
  @description('Network security group configuration')
  nsg: {
    enabled: bool
    rules: array?
  }?
  
  @description('Service endpoints')
  serviceEndpoints: string[]?
  
  @description('Delegation configuration')
  delegation: {
    name: string
    serviceName: string
  }?
}

@description('Firewall policy configuration type')
type firewallPolicyConfig = {
  @description('Threat intelligence mode')
  @allowed([
    'Alert'
    'Deny'
    'Off'
  ])
  threatIntelMode: string
  
  @description('IDPS mode (Premium only)')
  @allowed([
    'Alert'
    'Deny'
    'Off'
  ])
  idpsMode: string
  
  @description('Enable DNS proxy')
  dnsProxyEnabled: bool
  
  @description('Custom DNS servers')
  customDnsServers: string[]?
  
  @description('Enable TLS inspection (Premium only)')
  tlsInspectionEnabled: bool
  
  @description('Key Vault secret ID for TLS certificate')
  tlsKeyVaultSecretId: string?
}

@description('Network rule collection type')
type networkRuleCollection = {
  @description('Rule collection name')
  name: string
  
  @description('Priority (100-65000)')
  @minValue(100)
  @maxValue(65000)
  priority: int
  
  @description('Action type')
  @allowed([
    'Allow'
    'Deny'
  ])
  action: string
  
  @description('Network rules')
  rules: array
}

@description('Application rule collection type')
type applicationRuleCollection = {
  @description('Rule collection name')
  name: string
  
  @description('Priority (100-65000)')
  @minValue(100)
  @maxValue(65000)
  priority: int
  
  @description('Action type')
  @allowed([
    'Allow'
    'Deny'
  ])
  action: string
  
  @description('Application rules')
  rules: array
}

@description('VPN Gateway configuration type')
type vpnGatewayConfig = {
  @description('Gateway SKU')
  @allowed([
    'VpnGw1'
    'VpnGw2'
    'VpnGw3'
    'VpnGw4'
    'VpnGw5'
    'VpnGw1AZ'
    'VpnGw2AZ'
    'VpnGw3AZ'
    'VpnGw4AZ'
    'VpnGw5AZ'
  ])
  sku: string
  
  @description('Enable active-active configuration')
  activeActive: bool
  
  @description('Enable BGP')
  bgpEnabled: bool
  
  @description('BGP ASN (64512-65534 for private)')
  @minValue(64512)
  @maxValue(65534)
  bgpAsn: int?
}

@description('ExpressRoute Gateway configuration type')
type expressRouteGatewayConfig = {
  @description('Gateway SKU')
  @allowed([
    'Standard'
    'HighPerformance'
    'UltraPerformance'
    'ErGw1AZ'
    'ErGw2AZ'
    'ErGw3AZ'
  ])
  sku: string
}

@description('Diagnostic settings configuration type')
type diagnosticConfig = {
  @description('Enable diagnostic settings')
  enabled: bool
  
  @description('Log Analytics workspace resource ID')
  logAnalyticsWorkspaceId: string?
  
  @description('Storage account resource ID for logs')
  storageAccountId: string?
  
  @description('Retention in days')
  @minValue(0)
  @maxValue(365)
  retentionDays: int
}

@description('Tag configuration type')
type tagConfig = {
  @description('Environment tag')
  Environment: string
  
  @description('Cost center tag')
  CostCenter: string?
  
  @description('Owner tag')
  Owner: string?
  
  @description('Application tag')
  Application: string?
  
  @description('Additional tags')
  *: string?
}
