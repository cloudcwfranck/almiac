// Hub Network Parameters - Production Environment (Azure Commercial)
using '../../modules/hub-network/main.bicep'

param resourceGroupName = 'rg-hub-eus-prd'
param location = 'eastus'
param environment = 'prd'
param azureCloud = 'public'

// Network Configuration
param hubAddressPrefix = '10.100.0.0/16'
param firewallSubnetPrefix = '10.100.0.0/26'
param bastionSubnetPrefix = '10.100.1.0/26'
param gatewaySubnetPrefix = '10.100.2.0/27'
param managementSubnetPrefix = '10.100.3.0/24'
param sharedServicesSubnetPrefix = '10.100.4.0/24'

// Firewall Configuration
param firewallTier = 'Premium'
param firewallIdpsMode = 'Deny'
param enableTlsInspection = true
param tlsKeyVaultSecretId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-security-eus-prd/providers/Microsoft.KeyVault/vaults/kv-security-prd/secrets/firewall-tls-cert'
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
param logAnalyticsWorkspaceId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-monitoring-eus-prd/providers/Microsoft.OperationalInsights/workspaces/law-eus-prd'

// Tags
param tags = {
  CostCenter: 'IT-Production'
  Owner: 'CloudTeam'
  Project: 'Landing Zone'
  Criticality: 'Critical'
  Compliance: 'CIS-Azure-1.4.0'
  DataClassification: 'Confidential'
}
