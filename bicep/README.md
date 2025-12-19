# Azure Landing Zone - Bicep Modules

Enterprise-grade Bicep modules for deploying Azure Landing Zone hub-spoke network architecture with advanced security, compliance, and monitoring capabilities.

## Overview

This Bicep implementation provides a comprehensive infrastructure-as-code solution for Azure Landing Zone network topology, supporting both Azure Commercial and Azure Government clouds.

### Key Features

- **Hub-Spoke Network Topology**: Centralized hub with Azure Firewall, VPN/ExpressRoute gateways, and Azure Bastion
- **Azure Firewall Premium**: IDPS, TLS inspection, DNS proxy, and threat intelligence
- **Private DNS Zones**: Automated DNS for Azure PaaS services with multi-cloud support
- **Network Security**: NSGs with default-deny, NSG flow logs, Traffic Analytics
- **High Availability**: Zone-redundant deployments for critical resources
- **Private Connectivity**: Private endpoints with DNS integration
- **Advanced Bicep Features**: User-defined types, conditional deployments, modular architecture

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         HUB VNET                                │
│  ┌───────────────┐  ┌──────────────┐  ┌─────────────────────┐  │
│  │ Azure Firewall│  │Azure Bastion │  │  VPN/ExpressRoute   │  │
│  │   Premium     │  │   Premium    │  │     Gateways        │  │
│  └───────┬───────┘  └──────────────┘  └──────────┬──────────┘  │
│          │                                        │             │
│  ┌───────┴──────────────────────────────────────┴──────────┐   │
│  │         Management & Shared Services Subnets            │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
          │                          │                      │
    ┌─────▼─────┐             ┌──────▼──────┐      ┌──────▼──────┐
    │  Spoke 1  │             │   Spoke 2   │      │   Spoke N   │
    │  (WebApp) │             │    (AKS)    │      │   (Data)    │
    └───────────┘             └─────────────┘      └─────────────┘
```

## Module Structure

```
bicep/
├── modules/
│   ├── hub-network/
│   │   ├── main.bicep                 # Hub orchestrator
│   │   ├── types.bicep                # User-defined types
│   │   ├── vnet.bicep                 # Hub VNet with 5 subnets
│   │   ├── firewall.bicep             # Azure Firewall Premium
│   │   ├── bastion.bicep              # Azure Bastion
│   │   ├── gateway.bicep              # VPN/ExpressRoute gateways
│   │   ├── privateDns.bicep           # 9 Private DNS zones
│   │   ├── ddosProtection.bicep       # DDoS Protection Standard
│   │   └── diagnostics.bicep          # Diagnostic settings
│   └── spoke-network/
│       ├── main.bicep                 # Spoke orchestrator
│       ├── vnet.bicep                 # Spoke VNet with NSGs
│       ├── routeTable.bicep           # Route table to firewall
│       ├── peering.bicep              # VNet peering
│       ├── privateEndpoint.bicep      # Private endpoints
│       ├── flowLogs.bicep             # NSG flow logs
│       └── diagnostics.bicep          # Diagnostic settings
├── parameters/
│   ├── hub-network/
│   │   ├── dev-commercial.bicepparam
│   │   ├── prd-commercial.bicepparam
│   │   └── prd-government.bicepparam
│   └── spoke-network/
│       ├── dev-webapp.bicepparam
│       └── prd-webapp.bicepparam
├── scripts/
│   ├── deploy-hub.sh                  # Deploy hub network
│   ├── deploy-spoke.sh                # Deploy spoke network
│   ├── whatif-hub.sh                  # What-if analysis
│   ├── validate-all.sh                # Validate all modules
│   └── build-all.sh                   # Build to ARM templates
└── .bicepconfig.json                  # Bicep linter configuration
```

## Prerequisites

- Azure CLI 2.50.0 or later
- Bicep CLI 0.20.0 or later
- Azure subscription with appropriate permissions
- For Government cloud: Azure Government subscription

### Install Bicep CLI

```bash
az bicep install
az bicep upgrade
az bicep version
```

## Quick Start

### 1. Deploy Hub Network

```bash
# Development environment - Azure Commercial
cd bicep/scripts
./deploy-hub.sh dev commercial

# Production environment - Azure Government
./deploy-hub.sh prd government
```

### 2. Deploy Spoke Network

```bash
# Web application spoke - Development
./deploy-spoke.sh webapp dev

# Web application spoke - Production
./deploy-spoke.sh webapp prd
```

### 3. What-If Analysis

Before deploying, review changes:

```bash
./whatif-hub.sh dev commercial
```

## Deployment Options

### Option 1: Using Deployment Scripts

```bash
# Hub network
./scripts/deploy-hub.sh <environment> <cloud-type>

# Spoke network
./scripts/deploy-spoke.sh <workload> <environment>
```

### Option 2: Using Azure CLI

```bash
# Hub network
az deployment sub create \
  --name hub-network-deployment \
  --location eastus \
  --template-file modules/hub-network/main.bicep \
  --parameters parameters/hub-network/prd-commercial.bicepparam

# Spoke network
az deployment sub create \
  --name spoke-network-deployment \
  --location eastus \
  --template-file modules/spoke-network/main.bicep \
  --parameters parameters/spoke-network/prd-webapp.bicepparam
```

### Option 3: Using Azure Portal

1. Build Bicep to ARM template:
   ```bash
   ./scripts/build-all.sh
   ```

2. Upload `build/hub-network/main.json` to Azure Portal custom deployment

## Module Documentation

### Hub Network Module

See [modules/hub-network/README.md](modules/hub-network/README.md)

**Key Features:**
- 5 specialized subnets (Firewall, Bastion, Gateway, Management, Shared Services)
- Azure Firewall Premium with IDPS and TLS inspection
- Zone-redundant VPN and ExpressRoute gateways
- 9 Private DNS zones for Azure PaaS services
- DDoS Protection Standard (optional)
- Comprehensive diagnostic settings

**Parameters:**
- Network configuration (address spaces, subnet prefixes)
- Firewall policy (threat intelligence, IDPS mode, TLS inspection)
- Gateway configuration (SKUs, BGP, active-active)
- Availability zones
- Tags and metadata

### Spoke Network Module

See [modules/spoke-network/README.md](modules/spoke-network/README.md)

**Key Features:**
- Dynamic subnet creation with NSGs
- Automatic VNet peering with hub (bidirectional)
- Route tables with UDR to Azure Firewall
- Private endpoints with DNS integration
- NSG flow logs with Traffic Analytics
- Service endpoint and delegation support

**Parameters:**
- Workload-specific subnet configurations
- Hub VNet connection details
- Private endpoint configurations
- Flow log retention settings
- Tags and metadata

## Advanced Features

### User-Defined Types

Bicep modules leverage user-defined types for type safety:

```bicep
type subnetConfig = {
  name: string
  addressPrefix: string
  serviceEndpoints: array?
  delegations: array?
  securityRules: array?
}
```

### Conditional Deployments

Resources deploy based on feature flags:

```bicep
module vpnGateway './gateway.bicep' = if (enableVpnGateway) {
  // ... configuration
}
```

### Multi-Cloud Support

Automatic DNS zone naming for Azure Commercial vs Government:

```bicep
var dnsZones = azureCloud == 'usgovernment' ? [
  'privatelink.blob.core.usgovcloudapi.net'
] : [
  'privatelink.blob.core.windows.net'
]
```

## Validation and Testing

### Validate All Modules

```bash
./scripts/validate-all.sh
```

### Build to ARM Templates

```bash
./scripts/build-all.sh
# ARM templates saved to build/ directory
```

### Linting

Bicep linter is configured in `.bicepconfig.json` with strict rules:

```bash
az bicep build --file modules/hub-network/main.bicep
```

## Security Best Practices

### Network Security

- **Default Deny**: All NSGs include default deny rules
- **Private Endpoints**: Azure PaaS services accessible via private IPs
- **Zero Trust**: All traffic routed through Azure Firewall
- **Encryption**: TLS inspection for HTTPS traffic (Premium Firewall)

### Identity and Access

- **Managed Identities**: Resources use managed identities where possible
- **RBAC**: Least privilege access model
- **Key Vault**: TLS certificates stored in Azure Key Vault

### Monitoring and Compliance

- **Flow Logs**: NSG flow logs with Traffic Analytics
- **Diagnostic Settings**: All resources log to Log Analytics
- **Azure Policy**: CIS, NIST 800-53, FedRAMP compliance policies
- **Alerts**: Automated alerting for security events

## Cost Optimization

### Hub Network Costs (Monthly Estimates)

| Component | Dev | Production |
|-----------|-----|------------|
| Azure Firewall | $821 (Standard) | $1,314 (Premium) |
| VPN Gateway | $139 (VpnGw1) | $514 (VpnGw2AZ) |
| ExpressRoute | N/A | $514 (ErGw2AZ) |
| Azure Bastion | $146 (Standard) | $292 (Premium) |
| DDoS Protection | N/A | $2,944 |
| **Total** | **~$1,106** | **~$5,578** |

### Cost Reduction Tips

1. Use Azure Firewall Standard for non-production
2. Disable DDoS Protection Standard for dev/test
3. Use smaller gateway SKUs for dev/test
4. Implement auto-shutdown for non-production environments
5. Use Azure Reservations for predictable workloads

## Naming Conventions

Follows Cloud Adoption Framework (CAF) naming:

```
{resource-type}-{workload/app}-{region}-{environment}

Examples:
- vnet-hub-eus-prd
- fw-hub-eus-prd
- vnet-webapp-eus-dev
```

### Region Abbreviations

- `eus` = East US
- `wus` = West US
- `ugv` = US Gov Virginia
- `uga` = US Gov Arizona

### Environment Abbreviations

- `dev` = Development
- `stg` = Staging
- `prd` = Production

## Troubleshooting

### Common Issues

**Issue: Bicep deployment fails with "resource not found"**
```
Solution: Deploy hub network before spoke networks
```

**Issue: VNet peering fails**
```
Solution: Ensure hub VNet ID is correct in spoke parameters
Verify both subscriptions have Microsoft.Network provider registered
```

**Issue: Private DNS zone not resolving**
```
Solution: Verify VNet links created in Private DNS zones
Check that privateEndpointNetworkPolicies is 'Disabled' on subnet
```

**Issue: Azure Firewall rules not working**
```
Solution: Verify route table associated with spoke subnets
Check firewall rule collection priority and order
```

### Debugging

Enable verbose output:

```bash
az deployment sub create \
  --template-file modules/hub-network/main.bicep \
  --parameters parameters/hub-network/dev-commercial.bicepparam \
  --verbose \
  --debug
```

View deployment operations:

```bash
az deployment sub show \
  --name hub-network-deployment \
  --query properties.outputResources
```

## Support and Contributions

### Getting Help

- Azure Landing Zones: https://aka.ms/alz
- Bicep Documentation: https://aka.ms/bicep
- Azure Architecture Center: https://aka.ms/architecture

### Best Practices

- Always run what-if before production deployments
- Use parameter files for environment-specific configurations
- Version control all Bicep modules and parameters
- Implement CI/CD pipelines for automated deployments
- Regular security reviews and updates

## License

This project follows Azure Landing Zone guidelines and best practices.

## Changelog

### Version 1.0.0 (2025-12-19)

- Initial release
- Hub network module with Azure Firewall Premium
- Spoke network module with private endpoints
- Multi-cloud support (Commercial and Government)
- Comprehensive parameter files and deployment scripts
- Full documentation and examples
