// Hub Network Parameters - Production Environment (Azure Government)
using '../../modules/hub-network/main.bicep'

param resourceGroupName = 'rg-hub-ugv-prd'
param location = 'usgovvirginia'
param environment = 'prd'
param azureCloud = 'usgovernment'

// Network Configuration
param hubAddressPrefix = '10.200.0.0/16'
param firewallSubnetPrefix = '10.200.0.0/26'
param bastionSubnetPrefix = '10.200.1.0/26'
param gatewaySubnetPrefix = '10.200.2.0/27'
param managementSubnetPrefix = '10.200.3.0/24'
param sharedServicesSubnetPrefix = '10.200.4.0/24'

// Firewall Configuration
param firewallTier = 'Premium'
param firewallIdpsMode = 'Deny'
param enableTlsInspection = true
param tlsKeyVaultSecretId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-security-ugv-prd/providers/Microsoft.KeyVault/vaults/kv-security-prd/secrets/firewall-tls-cert'
param customDnsServers = []

// Bastion Configuration
param bastionSku = 'Premium'

// Gateway Configuration
param enableVpnGateway = true
param vpnGatewaySku = 'VpnGw2AZ'
param vpnActiveActive = true
param vpnEnableBgp = true
param vpnBgpAsn = 65515

param enableExpressRouteGateway = true
param expressRouteGatewaySku = 'ErGw2AZ'

// DDoS Protection
param enableDDoSProtection = true

// Availability Zones
param availabilityZones = [
  '1'
  '2'
  '3'
]

// Monitoring
param logAnalyticsWorkspaceId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-monitoring-ugv-prd/providers/Microsoft.OperationalInsights/workspaces/law-ugv-prd'

// Tags
param tags = {
  CostCenter: 'IT-Production'
  Owner: 'CloudTeam'
  Project: 'Landing Zone'
  Criticality: 'Mission Critical'
  Compliance: 'FedRAMP-High,NIST-800-53'
  DataClassification: 'Secret'
  ImpactLevel: 'IL5'
}
