// Hub Network Parameters - Development Environment (Azure Commercial)
using '../../modules/hub-network/main.bicep'

param resourceGroupName = 'rg-hub-eus-dev'
param location = 'eastus'
param environment = 'dev'
param azureCloud = 'public'

// Network Configuration
param hubAddressPrefix = '10.0.0.0/16'
param firewallSubnetPrefix = '10.0.0.0/26'
param bastionSubnetPrefix = '10.0.1.0/26'
param gatewaySubnetPrefix = '10.0.2.0/27'
param managementSubnetPrefix = '10.0.3.0/24'
param sharedServicesSubnetPrefix = '10.0.4.0/24'

// Firewall Configuration
param firewallTier = 'Standard'
param firewallIdpsMode = 'Alert'
param enableTlsInspection = false
param tlsKeyVaultSecretId = ''
param customDnsServers = []

// Bastion Configuration
param bastionSku = 'Standard'

// Gateway Configuration
param enableVpnGateway = true
param vpnGatewaySku = 'VpnGw1'
param vpnActiveActive = false
param vpnEnableBgp = true
param vpnBgpAsn = 65515

param enableExpressRouteGateway = false
param expressRouteGatewaySku = 'Standard'

// DDoS Protection
param enableDDoSProtection = false

// Availability Zones
param availabilityZones = [
  '1'
  '2'
  '3'
]

// Monitoring
param logAnalyticsWorkspaceId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-monitoring-eus-dev/providers/Microsoft.OperationalInsights/workspaces/law-eus-dev'

// Tags
param tags = {
  CostCenter: 'IT-Development'
  Owner: 'CloudTeam'
  Project: 'Landing Zone'
  Criticality: 'Low'
}
