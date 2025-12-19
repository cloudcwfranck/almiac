# Hub Network Module

Enterprise-grade hub network infrastructure for Azure Landing Zone with centralized security, connectivity, and monitoring.

## Overview

This module deploys a comprehensive hub network with:
- Azure Firewall Premium (or Standard) with advanced threat protection
- Azure Bastion for secure VM access
- VPN and ExpressRoute gateways for hybrid connectivity
- Private DNS zones for Azure PaaS services
- DDoS Protection Standard
- Network Watcher with flow logs
- Comprehensive diagnostic logging

## Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                          HUB VIRTUAL NETWORK                         │
│                           10.0.0.0/16                                │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ AzureFirewallSubnet (10.0.0.0/26)                          │   │
│  │  ┌──────────────────────────────────┐                      │   │
│  │  │  Azure Firewall Premium          │                      │   │
│  │  │  - IDPS (Intrusion Detection)    │                      │   │
│  │  │  - TLS Inspection                │                      │   │
│  │  │  - DNS Proxy                     │                      │   │
│  │  │  - Threat Intelligence           │                      │   │
│  │  │  Private IP: 10.0.0.4            │                      │   │
│  │  └──────────────────────────────────┘                      │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ AzureBastionSubnet (10.0.1.0/26)                           │   │
│  │  ┌──────────────────────────────────┐                      │   │
│  │  │  Azure Bastion Premium           │                      │   │
│  │  │  - Native client support         │                      │   │
│  │  │  - IP-based connection           │                      │   │
│  │  │  - Shareable links               │                      │   │
│  │  └──────────────────────────────────┘                      │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ GatewaySubnet (10.0.2.0/27)                                │   │
│  │  ┌────────────────────┐  ┌──────────────────────────────┐  │   │
│  │  │  VPN Gateway       │  │  ExpressRoute Gateway       │  │   │
│  │  │  - Active-Active   │  │  - FastPath                 │  │   │
│  │  │  - BGP Enabled     │  │  - Zone Redundant           │  │   │
│  │  │  - Zone Redundant  │  │                             │  │   │
│  │  └────────────────────┘  └──────────────────────────────┘  │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ Management Subnet (10.0.3.0/24)                            │   │
│  │  - Jump boxes, domain controllers, management VMs          │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ Shared Services Subnet (10.0.4.0/24)                       │   │
│  │  - Active Directory, DNS, monitoring agents                │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│                      PRIVATE DNS ZONES (9)                           │
├──────────────────────────────────────────────────────────────────────┤
│  - privatelink.blob.core.windows.net                                 │
│  - privatelink.file.core.windows.net                                 │
│  - privatelink.database.windows.net                                  │
│  - privatelink.vaultcore.azure.net                                   │
│  - privatelink.azurewebsites.net                                     │
│  - privatelink.azurecr.io                                            │
│  - privatelink.postgres.database.azure.com                           │
│  - privatelink.mysql.database.azure.com                              │
│  - privatelink.documents.azure.com                                   │
└──────────────────────────────────────────────────────────────────────┘
```

## Module Files

| File | Purpose |
|------|---------|
| `main.bicep` | Main orchestrator template |
| `types.bicep` | User-defined types for type safety |
| `vnet.bicep` | Hub VNet with 5 subnets and NSGs |
| `firewall.bicep` | Azure Firewall and firewall policy |
| `bastion.bicep` | Azure Bastion host |
| `gateway.bicep` | VPN and ExpressRoute gateways |
| `privateDns.bicep` | Private DNS zones with VNet links |
| `ddosProtection.bicep` | DDoS Protection Standard plan |
| `diagnostics.bicep` | Diagnostic settings for all resources |

## Parameters

### Required Parameters

```bicep
param resourceGroupName string        // Resource group name
param location string                 // Azure region
param environment string              // dev, stg, prd
param azureCloud string               // public, usgovernment
```

### Network Configuration

```bicep
param hubAddressPrefix string                  // Hub VNet address space (e.g., '10.0.0.0/16')
param firewallSubnetPrefix string              // /26 minimum
param bastionSubnetPrefix string               // /26 minimum
param gatewaySubnetPrefix string               // /27 minimum
param managementSubnetPrefix string            // /24 recommended
param sharedServicesSubnetPrefix string        // /24 recommended
```

### Azure Firewall Configuration

```bicep
param firewallTier string              // 'Standard' or 'Premium'
param firewallIdpsMode string          // 'Alert', 'Deny', or 'Off'
param enableTlsInspection bool         // true for HTTPS inspection
param tlsKeyVaultSecretId string       // Certificate for TLS inspection
param customDnsServers array           // Custom DNS servers (optional)
```

### Gateway Configuration

```bicep
param enableVpnGateway bool           // Deploy VPN Gateway
param vpnGatewaySku string            // VpnGw1, VpnGw2, VpnGw1AZ, VpnGw2AZ, etc.
param vpnActiveActive bool            // Active-active configuration
param vpnEnableBgp bool               // Enable BGP
param vpnBgpAsn int                   // BGP ASN (default: 65515)

param enableExpressRouteGateway bool  // Deploy ExpressRoute Gateway
param expressRouteGatewaySku string   // Standard, HighPerformance, ErGw1AZ, ErGw2AZ, etc.
```

### High Availability

```bicep
param enableDDoSProtection bool       // Enable DDoS Protection Standard
param availabilityZones array         // ['1', '2', '3']
```

### Monitoring

```bicep
param logAnalyticsWorkspaceId string  // Log Analytics workspace resource ID
```

## Outputs

```bicep
output hubVNetId string                    // Hub VNet resource ID
output hubVNetName string                  // Hub VNet name
output firewallPrivateIp string            // Firewall private IP for routing
output firewallId string                   // Firewall resource ID
output bastionId string                    // Bastion resource ID
output vpnGatewayId string                 // VPN Gateway resource ID (if enabled)
output expressRouteGatewayId string        // ExpressRoute Gateway ID (if enabled)
output privateDnsZoneIds object            // Private DNS zone resource IDs
output subnetIds object                    // All subnet resource IDs
```

## Usage Examples

### Development Environment

```bicep
// dev-commercial.bicepparam
using './main.bicep'

param resourceGroupName = 'rg-hub-eus-dev'
param location = 'eastus'
param environment = 'dev'
param azureCloud = 'public'

param hubAddressPrefix = '10.0.0.0/16'
param firewallTier = 'Standard'
param bastionSku = 'Standard'
param enableVpnGateway = true
param vpnGatewaySku = 'VpnGw1'
param enableExpressRouteGateway = false
param enableDDoSProtection = false
```

### Production Environment

```bicep
// prd-commercial.bicepparam
using './main.bicep'

param resourceGroupName = 'rg-hub-eus-prd'
param location = 'eastus'
param environment = 'prd'
param azureCloud = 'public'

param hubAddressPrefix = '10.100.0.0/16'
param firewallTier = 'Premium'
param firewallIdpsMode = 'Deny'
param enableTlsInspection = true
param bastionSku = 'Premium'
param enableVpnGateway = true
param vpnGatewaySku = 'VpnGw2AZ'
param vpnActiveActive = true
param enableExpressRouteGateway = true
param expressRouteGatewaySku = 'ErGw2AZ'
param enableDDoSProtection = true
```

## Deployment

### Using Deployment Script

```bash
cd bicep/scripts
./deploy-hub.sh prd commercial
```

### Using Azure CLI

```bash
az deployment sub create \
  --name hub-network-deployment \
  --location eastus \
  --template-file modules/hub-network/main.bicep \
  --parameters parameters/hub-network/prd-commercial.bicepparam
```

### What-If Analysis

```bash
az deployment sub what-if \
  --location eastus \
  --template-file modules/hub-network/main.bicep \
  --parameters parameters/hub-network/prd-commercial.bicepparam
```

## Firewall Rule Collections

The module includes pre-configured rule collections:

### Network Rules
- Allow DNS (UDP 53)
- Allow NTP (UDP 123)
- Allow Windows Update
- Allow Azure Monitor

### Application Rules
- Allow Microsoft services (*.microsoft.com, *.windows.net)
- Allow Ubuntu updates
- Allow certificate validation

### Customization

Edit `firewall.bicep` to add custom rules:

```bicep
{
  name: 'AllowSQLTraffic'
  ruleType: 'NetworkRule'
  ipProtocols: ['TCP']
  sourceAddresses: ['10.1.0.0/16']
  destinationAddresses: ['Sql']
  destinationPorts: ['1433']
}
```

## Security Considerations

### Network Segmentation

- Each subnet has dedicated NSG with default-deny rules
- All spoke traffic routed through Azure Firewall
- Private endpoints for Azure PaaS services
- No direct internet access from spokes

### Threat Protection

- **IDPS**: Inspects traffic for known attack signatures
- **TLS Inspection**: Decrypts and inspects HTTPS traffic
- **Threat Intelligence**: Blocks known malicious IPs/domains
- **DNS Proxy**: Prevents DNS exfiltration

### Access Control

- Azure Bastion for secure VM access (no public IPs)
- VPN Gateway with certificate-based authentication
- ExpressRoute for private WAN connectivity
- Just-in-time VM access

## Cost Optimization

### SKU Selection

| Component | Development | Production |
|-----------|-------------|------------|
| Firewall | Standard | Premium |
| VPN Gateway | VpnGw1 | VpnGw2AZ |
| ExpressRoute | Disabled | ErGw2AZ |
| Bastion | Standard | Premium |
| DDoS Protection | Disabled | Enabled |

### Cost-Saving Tips

1. **Dev/Test**: Disable DDoS Protection Standard ($2,944/month)
2. **Non-Prod**: Use Standard Firewall instead of Premium ($493/month savings)
3. **Right-Size Gateways**: Start with smaller SKUs and scale up as needed
4. **Reserved Instances**: Use Azure Reservations for predictable workloads

## Monitoring and Alerts

### Diagnostic Logs Collected

- Firewall application rule logs
- Firewall network rule logs
- Firewall DNS proxy logs
- VPN Gateway diagnostic logs
- NSG flow logs
- VNet diagnostic logs

### Recommended Alerts

1. Firewall IDPS detections
2. VPN connection failures
3. ExpressRoute circuit down
4. DDoS attack detected
5. High firewall CPU usage

## Troubleshooting

### Issue: Firewall deployment fails

**Symptom**: "AzureFirewallSubnet must be /26 or larger"

**Solution**: Increase firewall subnet prefix size:
```bicep
param firewallSubnetPrefix = '10.0.0.0/26'  // Not /27 or smaller
```

### Issue: TLS inspection not working

**Symptom**: HTTPS traffic not inspected

**Checklist**:
1. Verify `firewallTier = 'Premium'`
2. Confirm `enableTlsInspection = true`
3. Check certificate stored in Key Vault
4. Validate firewall has Key Vault access

### Issue: Private DNS not resolving

**Symptom**: Cannot resolve privatelink domains

**Solution**: Verify VNet links created:
```bash
az network private-dns link vnet show \
  --resource-group rg-hub-eus-prd \
  --zone-name privatelink.blob.core.windows.net \
  --name vnet-hub-link
```

## Best Practices

1. **Always enable DDoS Protection for production**
2. **Use Premium Firewall for TLS inspection in production**
3. **Enable zone redundancy for high availability**
4. **Implement active-active VPN for HA**
5. **Use ExpressRoute with VPN as backup**
6. **Enable diagnostic logging for all resources**
7. **Regular review of firewall rules and logs**
8. **Implement Azure Policy for compliance**

## Related Modules

- [Spoke Network Module](../spoke-network/README.md)
- [Monitoring Module](../../terraform/modules/monitoring/README.md)
- [Governance Module](../../terraform/modules/governance/README.md)

## References

- [Azure Firewall Premium](https://docs.microsoft.com/azure/firewall/premium-features)
- [Azure Bastion](https://docs.microsoft.com/azure/bastion/bastion-overview)
- [VPN Gateway](https://docs.microsoft.com/azure/vpn-gateway/)
- [ExpressRoute](https://docs.microsoft.com/azure/expressroute/)
- [Private DNS Zones](https://docs.microsoft.com/azure/dns/private-dns-overview)
