# Spoke Network Module

Workload-specific spoke network infrastructure for Azure Landing Zone with automatic hub peering, private endpoints, and centralized routing.

## Overview

This module deploys a spoke network for workloads with:
- Customizable subnets with Network Security Groups
- Automatic VNet peering with hub (bidirectional)
- Route tables with User-Defined Routes (UDR) to Azure Firewall
- Private endpoints for Azure PaaS services
- NSG flow logs with Traffic Analytics
- Service endpoints and subnet delegation
- Comprehensive diagnostic logging

## Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                    SPOKE VIRTUAL NETWORK                       │
│                      (WebApp - 10.1.0.0/16)                    │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  ┌──────────────────────────────────────────────────────┐     │
│  │ Frontend Subnet (10.1.0.0/24)                       │     │
│  │  ┌────────────────────────────────────┐             │     │
│  │  │ NSG: AllowHttpsInbound             │             │     │
│  │  │  - Application Gateway             │             │     │
│  │  │  - Web servers                     │             │     │
│  │  └────────────────────────────────────┘             │     │
│  └──────────────────────────────────────────────────────┘     │
│                          ↓                                     │
│  ┌──────────────────────────────────────────────────────┐     │
│  │ Backend Subnet (10.1.1.0/24)                        │     │
│  │  ┌────────────────────────────────────┐             │     │
│  │  │ NSG: AllowFrontendTraffic          │             │     │
│  │  │  - API servers                     │             │     │
│  │  │  - Application logic               │             │     │
│  │  └────────────────────────────────────┘             │     │
│  └──────────────────────────────────────────────────────┘     │
│                          ↓                                     │
│  ┌──────────────────────────────────────────────────────┐     │
│  │ Data Subnet (10.1.2.0/24)                           │     │
│  │  ┌────────────────────────────────────┐             │     │
│  │  │ NSG: AllowBackendTraffic           │             │     │
│  │  │ Private Endpoints:                 │             │     │
│  │  │  - Azure SQL Database              │             │     │
│  │  │  - Azure Storage                   │             │     │
│  │  │  - Azure Key Vault                 │             │     │
│  │  └────────────────────────────────────┘             │     │
│  └──────────────────────────────────────────────────────┘     │
│                                                                │
│  ┌──────────────────────────────────────────────────────┐     │
│  │ Route Table                                          │     │
│  │  - 0.0.0.0/0 → Azure Firewall (10.0.0.4)           │     │
│  │  - Internet → Azure Firewall                        │     │
│  └──────────────────────────────────────────────────────┘     │
│                                                                │
└───────────────────────┬────────────────────────────────────────┘
                        │
                        │ VNet Peering
                        │ (UseRemoteGateways: true)
                        │
┌───────────────────────▼────────────────────────────────────────┐
│                     HUB VIRTUAL NETWORK                        │
│  ┌──────────────┐  ┌────────────┐  ┌──────────────────┐       │
│  │Azure Firewall│  │   Bastion  │  │  VPN/ExpressRoute│       │
│  └──────────────┘  └────────────┘  └──────────────────┘       │
└────────────────────────────────────────────────────────────────┘
```

## Module Files

| File | Purpose |
|------|---------|
| `main.bicep` | Main orchestrator template |
| `vnet.bicep` | Spoke VNet with dynamic subnets and NSGs |
| `routeTable.bicep` | Route table with UDR to firewall |
| `routeTableAssociation.bicep` | Associate route tables with subnets |
| `peering.bicep` | VNet peering (reusable) |
| `privateEndpoint.bicep` | Private endpoint creation |
| `flowLogs.bicep` | NSG flow logs with Traffic Analytics |
| `diagnostics.bicep` | Diagnostic settings for spoke resources |
| `subnetUpdate.bicep` | Helper for updating subnet properties |

## Parameters

### Required Parameters

```bicep
param resourceGroupName string        // Resource group name
param location string                 // Azure region
param environment string              // dev, stg, prd
param workloadName string             // webapp, aks, data, etc.
```

### Network Configuration

```bicep
param spokeAddressPrefix string      // Spoke VNet address space (e.g., '10.1.0.0/16')

param subnetConfigurations array = [
  {
    name: 'frontend'
    addressPrefix: '10.1.0.0/24'
    serviceEndpoints: [...]
    delegations: [...]
    securityRules: [...]
  }
]
```

### Hub Integration

```bicep
param hubVNetId string                // Hub VNet resource ID
param hubResourceGroupName string     // Hub resource group name
param firewallPrivateIp string        // Hub firewall IP for routing
param useRemoteGateways bool          // Use hub VPN/ExpressRoute gateways
param hubAllowGatewayTransit bool     // Hub allows gateway transit
```

### Private DNS Integration

```bicep
param privateDnsZoneIds array         // Private DNS zone resource IDs
```

### Private Endpoints

```bicep
param privateEndpointConfigurations array = [
  {
    name: 'sql-server'
    subnetName: 'data'
    privateLinkServiceId: '/subscriptions/.../sqlServer'
    groupIds: ['sqlServer']
    privateDnsZoneIds: [...]
  }
]
```

### Flow Logs

```bicep
param enableNsgFlowLogs bool          // Enable NSG flow logs
param flowLogsRetentionDays int       // Retention period
param networkWatcherName string       // Network Watcher name
param flowLogsStorageAccountId string // Storage for flow logs
param logAnalyticsWorkspaceId string  // Log Analytics workspace
```

## Outputs

```bicep
output spokeVNetId string              // Spoke VNet resource ID
output spokeVNetName string            // Spoke VNet name
output subnetIds object                // Subnet resource IDs
output nsgIds object                   // NSG resource IDs
output routeTableId string             // Route table resource ID
output privateEndpointIds array        // Private endpoint resource IDs
```

## Usage Examples

### Web Application Spoke

```bicep
// dev-webapp.bicepparam
using './main.bicep'

param resourceGroupName = 'rg-webapp-eus-dev'
param location = 'eastus'
param environment = 'dev'
param workloadName = 'webapp'

param spokeAddressPrefix = '10.1.0.0/16'

param subnetConfigurations = [
  {
    name: 'frontend'
    addressPrefix: '10.1.0.0/24'
    serviceEndpoints: [
      { service: 'Microsoft.Web' }
      { service: 'Microsoft.KeyVault' }
    ]
    securityRules: [
      {
        name: 'AllowHttpsInbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
  {
    name: 'backend'
    addressPrefix: '10.1.1.0/24'
    serviceEndpoints: [
      { service: 'Microsoft.Sql' }
    ]
  }
  {
    name: 'data'
    addressPrefix: '10.1.2.0/24'
    privateEndpointNetworkPolicies: 'Disabled'
  }
]

param hubVNetId = '/subscriptions/.../virtualNetworks/vnet-hub-eus-dev'
param firewallPrivateIp = '10.0.0.4'
param useRemoteGateways = true
```

### AKS Spoke with Subnet Delegation

```bicep
param subnetConfigurations = [
  {
    name: 'aks'
    addressPrefix: '10.2.0.0/22'
    delegations: [
      {
        name: 'aks-delegation'
        properties: {
          serviceName: 'Microsoft.ContainerService/managedClusters'
        }
      }
    ]
    associateRouteTable: false  // AKS manages its own routing
  }
  {
    name: 'appgw'
    addressPrefix: '10.2.10.0/24'
    delegations: [
      {
        name: 'appgw-delegation'
        properties: {
          serviceName: 'Microsoft.Network/applicationGateways'
        }
      }
    ]
  }
]
```

### Data Spoke with Multiple Private Endpoints

```bicep
param privateEndpointConfigurations = [
  {
    name: 'sql-server'
    subnetName: 'data'
    privateLinkServiceId: '/subscriptions/.../sqlServers/sql-prd'
    groupIds: ['sqlServer']
    privateDnsZoneIds: ['/.../privatelink.database.windows.net']
  }
  {
    name: 'storage-account-blob'
    subnetName: 'data'
    privateLinkServiceId: '/subscriptions/.../storageAccounts/stprd'
    groupIds: ['blob']
    privateDnsZoneIds: ['/.../privatelink.blob.core.windows.net']
  }
  {
    name: 'storage-account-file'
    subnetName: 'data'
    privateLinkServiceId: '/subscriptions/.../storageAccounts/stprd'
    groupIds: ['file']
    privateDnsZoneIds: ['/.../privatelink.file.core.windows.net']
  }
  {
    name: 'key-vault'
    subnetName: 'data'
    privateLinkServiceId: '/subscriptions/.../vaults/kv-prd'
    groupIds: ['vault']
    privateDnsZoneIds: ['/.../privatelink.vaultcore.azure.net']
  }
]
```

## Deployment

### Using Deployment Script

```bash
cd bicep/scripts
./deploy-spoke.sh webapp dev
```

### Using Azure CLI

```bash
az deployment sub create \
  --name spoke-webapp-deployment \
  --location eastus \
  --template-file modules/spoke-network/main.bicep \
  --parameters parameters/spoke-network/dev-webapp.bicepparam
```

### What-If Analysis

```bash
az deployment sub what-if \
  --location eastus \
  --template-file modules/spoke-network/main.bicep \
  --parameters parameters/spoke-network/dev-webapp.bicepparam
```

## Subnet Configuration

### Security Rules

NSGs include default-deny rules. Add custom rules for your workload:

```bicep
securityRules: [
  {
    name: 'AllowHttpsInbound'
    properties: {
      description: 'Allow HTTPS from internet'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '443'
      sourceAddressPrefix: 'Internet'
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 100
      direction: 'Inbound'
    }
  }
]
```

### Service Endpoints

Enable service endpoints for Azure PaaS services:

```bicep
serviceEndpoints: [
  { service: 'Microsoft.Sql' }
  { service: 'Microsoft.Storage' }
  { service: 'Microsoft.KeyVault' }
  { service: 'Microsoft.Web' }
  { service: 'Microsoft.ContainerRegistry' }
]
```

### Subnet Delegation

Delegate subnets for specific services:

```bicep
// AKS
delegations: [
  {
    name: 'aks-delegation'
    properties: {
      serviceName: 'Microsoft.ContainerService/managedClusters'
    }
  }
]

// App Service
delegations: [
  {
    name: 'appservice-delegation'
    properties: {
      serviceName: 'Microsoft.Web/serverFarms'
    }
  }
]

// NetApp Files
delegations: [
  {
    name: 'netapp-delegation'
    properties: {
      serviceName: 'Microsoft.NetApp/volumes'
    }
  }
]
```

## Routing

### Default Routes

All spoke subnets have default route to Azure Firewall:

```
Destination: 0.0.0.0/0
Next Hop: Virtual Appliance
Next Hop IP: 10.0.0.4 (Firewall private IP)
```

### Skip Route Table Association

For subnets that manage their own routing (e.g., AKS):

```bicep
{
  name: 'aks'
  addressPrefix: '10.2.0.0/22'
  associateRouteTable: false  // Skip route table
}
```

## Private Endpoints

### Supported Services

- Azure SQL Database (`sqlServer`)
- Azure Storage (`blob`, `file`, `queue`, `table`, `dfs`)
- Azure Key Vault (`vault`)
- Azure Cosmos DB (`Sql`, `MongoDB`, `Cassandra`)
- Azure App Service (`sites`)
- Azure Container Registry (`registry`)
- Azure PostgreSQL (`postgresqlServer`)
- Azure MySQL (`mysqlServer`)
- Azure Event Hub (`namespace`)
- Azure Service Bus (`namespace`)

### DNS Integration

Private endpoints automatically integrate with Private DNS zones:

```bicep
{
  name: 'sql-private-endpoint'
  privateLinkServiceId: '/subscriptions/.../sqlServers/sql-prd'
  groupIds: ['sqlServer']
  privateDnsZoneIds: [
    '/subscriptions/.../privateDnsZones/privatelink.database.windows.net'
  ]
}
```

## NSG Flow Logs

### Traffic Analytics

Flow logs enable Traffic Analytics for visibility:

- Top talkers
- Application port usage
- Malicious traffic detection
- Geo map of traffic
- Virtual network topology

### Storage Requirements

Flow logs require a storage account:

```bicep
param flowLogsStorageAccountId = '/subscriptions/.../storageAccounts/stflowlogs'
param flowLogsRetentionDays = 90  // Production: 90 days, Dev: 7 days
```

## Security Considerations

### Network Isolation

- **Default Deny**: All NSGs start with deny-all rule
- **Zero Trust**: All traffic routed through Azure Firewall
- **Private Endpoints**: Azure PaaS services use private IPs
- **No Internet**: No direct internet access (routed through firewall)

### Access Control

- **NSG Rules**: Whitelist required traffic only
- **Service Endpoints**: Restrict PaaS access to specific VNets
- **Private Link**: Azure PaaS accessible only via private endpoint
- **Firewall Rules**: Centralized control in hub

### Compliance

- **Flow Logs**: Required for SOC 2, ISO 27001
- **Traffic Analytics**: Security monitoring and threat detection
- **Diagnostic Logs**: All network events logged
- **Azure Policy**: Automated compliance enforcement

## Monitoring and Alerts

### Diagnostic Logs

- VNet diagnostic logs
- NSG flow logs (version 2)
- NSG event logs
- NSG rule counter logs

### Recommended Alerts

1. Unexpected traffic from/to internet
2. High volume of denied traffic
3. Peering state changed
4. NSG rule modification
5. Private endpoint connection state change

## Cost Optimization

### Per Spoke Costs (Monthly Estimates)

| Component | Dev | Production |
|-----------|-----|------------|
| VNet | Free | Free |
| NSGs | Free | Free |
| Route Tables | Free | Free |
| VNet Peering (Data Transfer) | $10-50 | $100-500 |
| Private Endpoints | $7.30 each | $7.30 each |
| Flow Logs (Storage) | $5-20 | $50-200 |
| **Total (3 endpoints)** | **~$40** | **~$360** |

### Cost-Saving Tips

1. **Consolidate Private Endpoints**: Use shared data subnet
2. **Reduce Flow Log Retention**: 7 days for dev vs 90 for production
3. **Disable Traffic Analytics**: For non-production environments
4. **Optimize Peering**: Minimize cross-region traffic

## Troubleshooting

### Issue: VNet peering fails

**Symptom**: Peering stuck in "Updating" state

**Solutions**:
1. Verify hub VNet ID is correct
2. Check RBAC permissions on hub VNet
3. Ensure no overlapping address spaces
4. Verify Microsoft.Network provider is registered

```bash
# Check peering state
az network vnet peering show \
  --resource-group rg-webapp-eus-dev \
  --vnet-name vnet-webapp-eus-dev \
  --name peer-spoke-to-hub

# Re-sync peering
az network vnet peering sync \
  --resource-group rg-webapp-eus-dev \
  --vnet-name vnet-webapp-eus-dev \
  --name peer-spoke-to-hub
```

### Issue: Private endpoint not resolving

**Symptom**: Cannot connect to Azure PaaS service via private IP

**Checklist**:
1. Verify private endpoint provisioning state is "Succeeded"
2. Check Private DNS zone has VNet link to spoke VNet
3. Confirm `privateEndpointNetworkPolicies = 'Disabled'` on subnet
4. Test DNS resolution: `nslookup <service>.database.windows.net`

### Issue: Traffic not routing through firewall

**Symptom**: Traffic bypassing Azure Firewall

**Solutions**:
1. Verify route table associated with subnet
2. Check route propagation not disabled
3. Confirm firewall private IP correct (10.0.0.4)
4. Review effective routes on VM NIC

```bash
# Check effective routes
az network nic show-effective-route-table \
  --resource-group rg-webapp-eus-dev \
  --name vm-nic-001 \
  --output table
```

### Issue: NSG flow logs not working

**Symptom**: No flow logs appearing in storage

**Checklist**:
1. Verify storage account in same region as NSG
2. Check Network Watcher enabled in region
3. Confirm flow log resource provisioned
4. Validate storage account has containers: `insights-logs-networksecuritygroupflowevent`

## Best Practices

1. **One spoke per workload**: Separate web, data, AKS workloads
2. **Use service endpoints AND private endpoints**: Defense in depth
3. **Enable flow logs**: Required for security monitoring
4. **Implement micro-segmentation**: Separate frontend, backend, data subnets
5. **Use hub gateways**: Enable `useRemoteGateways = true`
6. **Tag all resources**: Cost allocation and governance
7. **Regular NSG review**: Remove unused rules
8. **Automate with CI/CD**: GitHub Actions or Azure DevOps

## Related Modules

- [Hub Network Module](../hub-network/README.md)
- [Monitoring Module](../../terraform/modules/monitoring/README.md)
- [Governance Module](../../terraform/modules/governance/README.md)

## References

- [Virtual Network Peering](https://docs.microsoft.com/azure/virtual-network/virtual-network-peering-overview)
- [Private Endpoints](https://docs.microsoft.com/azure/private-link/private-endpoint-overview)
- [NSG Flow Logs](https://docs.microsoft.com/azure/network-watcher/network-watcher-nsg-flow-logging-overview)
- [Service Endpoints](https://docs.microsoft.com/azure/virtual-network/virtual-network-service-endpoints-overview)
- [Subnet Delegation](https://docs.microsoft.com/azure/virtual-network/subnet-delegation-overview)
