# Hub Network Module

Enterprise-grade Azure hub network module implementing hub-spoke topology with Azure Firewall Premium, Azure Bastion, VPN/ExpressRoute Gateways, and comprehensive network security.

## Network Topology

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              HUB VIRTUAL NETWORK                             │
│                                  10.0.0.0/16                                 │
│                                                                              │
│  ┌──────────────────────┐  ┌──────────────────────┐  ┌──────────────────┐ │
│  │  AzureFirewallSubnet │  │ AzureBastionSubnet   │  │   GatewaySubnet   │ │
│  │     10.0.1.0/26      │  │    10.0.2.0/26       │  │    10.0.3.0/27    │ │
│  │                      │  │                      │  │                   │ │
│  │  ┌───────────────┐  │  │  ┌───────────────┐  │  │  ┌─────────────┐  │ │
│  │  │ Azure Firewall│  │  │  │ Azure Bastion │  │  │  │ VPN Gateway │  │ │
│  │  │   Premium     │  │  │  │   Standard    │  │  │  │  VpnGw2AZ   │  │ │
│  │  │               │  │  │  │               │  │  │  │             │  │ │
│  │  │ - IDPS: Alert │  │  │  │ - Copy/Paste  │  │  │  │ - BGP       │  │ │
│  │  │ - TLS Insp.   │  │  │  │ - File Copy   │  │  │  │ - Active-   │  │ │
│  │  │ - DNS Proxy   │  │  │  │ - Tunneling   │  │  │  │   Active    │  │ │
│  │  │               │  │  │  │               │  │  │  │             │  │ │
│  │  │ Public IP:    │  │  │  │ Public IP:    │  │  │  │ Public IP:  │  │ │
│  │  │ 40.x.x.x      │  │  │  │ 40.y.y.y      │  │  │  │ 40.z.z.z    │  │ │
│  │  │               │  │  │  │               │  │  │  │             │  │ │
│  │  │ Private IP:   │  │  │  └───────────────┘  │  │  └─────────────┘  │ │
│  │  │ 10.0.1.4      │  │  │                      │  │                   │ │
│  │  └───────────────┘  │  └──────────────────────┘  └──────────────────┘ │
│  └──────────────────────┘                                                  │
│                                                                              │
│  ┌──────────────────────────┐  ┌───────────────────────────────────────┐   │
│  │   Management Subnet      │  │   Shared Services Subnet              │   │
│  │     10.0.4.0/24          │  │      10.0.5.0/24                      │   │
│  │                          │  │                                        │   │
│  │  - Jump Boxes            │  │  - DNS Servers                         │   │
│  │  - Build Agents          │  │  - Active Directory Domain Controllers │   │
│  │  - DevOps Tools          │  │  - Certificate Authority               │   │
│  │                          │  │  - WSUS                                │   │
│  │  NSG: RDP/SSH from       │  │                                        │   │
│  │       Bastion only       │  │  NSG: DNS, LDAP, Kerberos from VNet    │   │
│  └──────────────────────────┘  └───────────────────────────────────────┘   │
│                                                                              │
│  Route Table: 0.0.0.0/0 → Azure Firewall (10.0.1.4)                        │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                    ┌─────────────────┼─────────────────┐
                    │                 │                 │
            ┌───────▼────────┐ ┌──────▼──────┐ ┌───────▼────────┐
            │  Spoke VNet 1  │ │ Spoke VNet 2│ │  Spoke VNet 3  │
            │  10.1.0.0/16   │ │ 10.2.0.0/16 │ │  10.3.0.0/16   │
            │                │ │             │ │                │
            │  VNet Peering: │ │ VNet Peering│ │  VNet Peering: │
            │  - UseRemote   │ │ - UseRemote │ │  - UseRemote   │
            │    Gateways    │ │   Gateways  │ │    Gateways    │
            │  - Allow       │ │ - Allow     │ │  - Allow       │
            │    Forwarded   │ │   Forwarded │ │    Forwarded   │
            └────────────────┘ └─────────────┘ └────────────────┘

Private DNS Zones (linked to hub):
  - privatelink.blob.core.windows.net
  - privatelink.file.core.windows.net
  - privatelink.vaultcore.azure.net
  - privatelink.database.windows.net
  - privatelink.azurecr.io
  - privatelink.azurewebsites.net
```

## Traffic Flow

### Internet Outbound Traffic
```
Spoke VM → Spoke Route Table → Hub Firewall → Internet
10.1.1.10  0.0.0.0/0 → 10.0.1.4  Application Rules → Public IP
```

### East-West Traffic (Spoke-to-Spoke)
```
Spoke 1 VM → Hub Firewall → Spoke 2 VM
10.1.1.10    10.0.1.4       10.2.1.10
             Network Rules
```

### On-Premises to Azure
```
On-Prem → VPN Gateway → Hub VNet → Firewall → Spoke VNets
192.168.x.x  BGP/IPsec   10.0.3.x  10.0.1.4   10.x.0.0/16
```

### Management Access
```
Admin → Azure Bastion → Jump Box → Spoke Resources
        Public IP        10.0.4.x   SSH/RDP
                         (via private IP only)
```

## Features

### Azure Firewall Premium
- **IDPS**: Intrusion Detection and Prevention System with signature-based detection
- **TLS Inspection**: Decrypt and inspect HTTPS traffic for threats
- **URL Filtering**: FQDN-based filtering with wildcard support
- **Web Categories**: Block/allow based on web content categories
- **Threat Intelligence**: Microsoft threat intelligence feed
- **DNS Proxy**: Forward and filter DNS requests

### Network Security
- **NSGs**: Network Security Groups on all subnets with default deny
- **Flow Logs**: NSG flow logs with Traffic Analytics
- **DDoS Protection**: Optional Standard tier ($3000/month)
- **Private DNS**: Automatic DNS resolution for private endpoints
- **Forced Tunneling**: Optional forced tunneling for compliance

### High Availability
- **Zone Redundancy**: Resources deployed across availability zones (1, 2, 3)
- **Active-Active VPN**: Dual VPN tunnels for redundancy
- **Firewall Zones**: Azure Firewall deployed in zones for 99.99% SLA

### Monitoring & Compliance
- **Diagnostic Settings**: All network resources send logs to Log Analytics
- **Network Watcher**: Enabled for connection monitoring and diagnostics
- **Traffic Analytics**: AI-powered network traffic analysis
- **Compliance**: Supports FedRAMP, NIST 800-53, CIS Benchmarks

## Usage

### Basic Example

```hcl
module "hub_network" {
  source = "./modules/hub-network"

  resource_group_name = "rg-network-hub-prd-eus"
  location            = "eastus"
  environment         = "prod"
  azure_cloud         = "public"

  # Network Configuration
  hub_address_space                     = ["10.0.0.0/16"]
  firewall_subnet_address_prefix        = "10.0.1.0/26"
  bastion_subnet_address_prefix         = "10.0.2.0/26"
  gateway_subnet_address_prefix         = "10.0.3.0/27"
  management_subnet_address_prefix      = "10.0.4.0/24"
  shared_services_subnet_address_prefix = "10.0.5.0/24"

  # Azure Firewall
  firewall_sku_tier = "Premium"
  idps_mode         = "Alert"

  # VPN Gateway
  enable_vpn_gateway        = true
  vpn_gateway_sku           = "VpnGw2AZ"
  vpn_gateway_enable_bgp    = true
  vpn_gateway_active_active = true

  # Monitoring
  log_analytics_workspace_id = module.management.log_analytics_workspace_id

  tags = {
    CostCenter  = "IT-OPS-001"
    Criticality = "Mission-Critical"
  }
}
```

### Advanced Example with Custom Rules

```hcl
module "hub_network" {
  source = "./modules/hub-network"

  # ... basic configuration ...

  # Custom Network Rules
  custom_network_rules = [
    {
      name     = "AllowOnPremises"
      priority = 200
      action   = "Allow"
      rules = [
        {
          name                  = "AllowRDP"
          protocols             = ["TCP"]
          source_addresses      = ["192.168.0.0/16"]
          destination_addresses = ["10.0.0.0/8"]
          destination_ports     = ["3389"]
        }
      ]
    }
  ]

  # Custom Application Rules
  custom_application_rules = [
    {
      name     = "AllowDevelopment"
      priority = 300
      action   = "Allow"
      rules = [
        {
          name = "AllowGitHub"
          protocols = [
            { type = "Https", port = 443 }
          ]
          source_addresses  = ["10.0.0.0/8"]
          destination_fqdns = ["github.com", "*.github.com"]
        }
      ]
    }
  ]

  # DNAT Rules
  dnat_rules = [
    {
      name     = "WebServer"
      priority = 100
      rules = [
        {
          name               = "HTTPS"
          protocols          = ["TCP"]
          source_addresses   = ["*"]
          destination_ports  = ["443"]
          translated_address = "10.1.1.10"
          translated_port    = "443"
        }
      ]
    }
  ]
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | ~> 3.80 |

## Providers

| Name | Version |
|------|---------|
| azurerm | ~> 3.80 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| resource_group_name | Name of the resource group | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| environment | Environment name | `string` | n/a | yes |
| hub_address_space | Hub VNet address space | `list(string)` | n/a | yes |
| firewall_subnet_address_prefix | Firewall subnet (min /26) | `string` | n/a | yes |
| bastion_subnet_address_prefix | Bastion subnet (min /26) | `string` | n/a | yes |
| gateway_subnet_address_prefix | Gateway subnet (min /27) | `string` | n/a | yes |
| management_subnet_address_prefix | Management subnet | `string` | n/a | yes |
| shared_services_subnet_address_prefix | Shared services subnet | `string` | n/a | yes |
| firewall_sku_tier | Firewall SKU (Standard/Premium) | `string` | `"Premium"` | no |
| idps_mode | IDPS mode (Alert/Deny/Off) | `string` | `"Alert"` | no |
| enable_vpn_gateway | Enable VPN Gateway | `bool` | `true` | no |
| vpn_gateway_sku | VPN Gateway SKU | `string` | `"VpnGw2AZ"` | no |
| enable_expressroute_gateway | Enable ExpressRoute Gateway | `bool` | `false` | no |
| availability_zones | Availability zones | `list(string)` | `["1","2","3"]` | no |
| enable_ddos_protection | Enable DDoS Protection | `bool` | `false` | no |
| log_analytics_workspace_id | Log Analytics workspace ID | `string` | `null` | no |

See [variables.tf](variables.tf) for complete list.

## Outputs

| Name | Description |
|------|-------------|
| hub_vnet_id | ID of hub virtual network |
| firewall_private_ip | Private IP of Azure Firewall |
| firewall_public_ip | Public IP of Azure Firewall |
| bastion_dns_name | DNS name of Azure Bastion |
| vpn_gateway_id | ID of VPN Gateway |
| private_dns_zone_ids | Map of private DNS zone IDs |
| subnet_ids | Map of all subnet IDs |

See [outputs.tf](outputs.tf) for complete list.

## Examples

- [Azure Commercial Cloud](examples/commercial-cloud.tfvars)
- [Azure Government Cloud](examples/government-cloud.tfvars)

## Network Design Decisions

### Subnet Sizing

- **AzureFirewallSubnet**: /26 (minimum required, supports 2-250 IPs)
- **AzureBastionSubnet**: /26 (minimum required)
- **GatewaySubnet**: /27 (minimum, /26 recommended for ExpressRoute)
- **Management**: /24 (254 usable IPs for jump boxes, build agents)
- **Shared Services**: /24 (254 usable IPs for DNS, AD DS, etc.)

### Why Azure Firewall Premium?

- **TLS Inspection**: Required for FedRAMP High and many compliance frameworks
- **IDPS**: Signature-based intrusion prevention
- **URL Filtering**: Advanced web content filtering
- **Worth the cost** for production enterprise workloads

### BGP for VPN Gateway

BGP is enabled by default for:
- Automatic route propagation
- Support for multiple on-premises sites
- Active-active configuration
- ExpressRoute integration

## Cost Estimates (Monthly)

| Component | SKU | Est. Cost (USD) |
|-----------|-----|-----------------|
| Azure Firewall Premium | Standard | $1,425 |
| Azure Bastion | Standard | $143 |
| VPN Gateway | VpnGw2AZ | $472 |
| Public IPs (3x) | Standard | $11 |
| DDoS Protection (optional) | Standard | $2,944 |
| NSG Flow Logs Storage | Standard | $20-50 |
| **Total (without DDoS)** | | **~$2,100/mo** |
| **Total (with DDoS)** | | **~$5,000/mo** |

*Costs are estimates and vary by region and data transfer.*

## Compliance

This module helps achieve compliance with:

- **FedRAMP Moderate/High**: TLS inspection, IDPS, logging
- **NIST 800-53**: Network segmentation, access controls
- **CIS Azure Benchmark**: Secure network configuration
- **PCI DSS**: Network isolation, monitoring
- **HIPAA**: Encryption in transit, audit logs

## Troubleshooting

### Firewall Not Routing Traffic

Check route tables:
```bash
az network route-table route list --resource-group rg-network-hub-prd-eus --route-table-name rt-hub-eus-prd
```

### VPN Gateway Takes 45+ Minutes

This is normal. VPN Gateways take 30-45 minutes to provision.

### Private DNS Not Resolving

Ensure VNet link is created:
```bash
az network private-dns link vnet list --resource-group rg-network-hub-prd-eus --zone-name privatelink.blob.core.windows.net
```

## License

MIT

## Authors

Cloud Platform Team
