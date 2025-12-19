# Spoke Network Module

Landing zone spoke network module for Azure hub-spoke topology with automatic hub peering, NSG flow logs, private endpoints, and route table management.

## Network Topology

```
┌───────────────────────────────────────────────────────────────────────────┐
│                         SPOKE VIRTUAL NETWORK                              │
│                         vnet-webapp-prd-eus                               │
│                           10.1.0.0/16                                     │
│                                                                            │
│  ┌──────────────────────┐  ┌──────────────────────┐  ┌─────────────────┐│
│  │  snet-frontend       │  │  snet-application    │  │  snet-database  ││
│  │    10.1.1.0/24       │  │    10.1.2.0/24       │  │   10.1.3.0/24   ││
│  │                      │  │                      │  │                 ││
│  │  ┌────────────────┐ │  │  ┌────────────────┐ │  │  ┌────────────┐ ││
│  │  │ App Gateway    │ │  │  │ App Services   │ │  │  │ Private    │ ││
│  │  │ / Load Balancer│ │  │  │ / VMs          │ │  │  │ Endpoints  │ ││
│  │  │                │ │  │  │                │ │  │  │            │ ││
│  │  │ - HTTPS:443    │ │  │  │ - App Port     │ │  │  │ - SQL DB   │ ││
│  │  │ - HTTP:80      │ │  │  │ - Internal     │ │  │  │ - Storage  │ ││
│  │  │   (→HTTPS)     │ │  │  │   traffic      │ │  │  │ - Key Vault│ ││
│  │  └────────────────┘ │  │  └────────────────┘ │  │  └────────────┘ ││
│  │                      │  │                      │  │                 ││
│  │  NSG Rules:          │  │  NSG Rules:          │  │  NSG Rules:     ││
│  │  ✓ Allow HTTPS       │  │  ✓ Allow from        │  │  ✓ Allow SQL    ││
│  │    from Internet     │  │    Frontend          │  │    from App     ││
│  │  ✓ Allow HTTP        │  │  ✗ Deny all other    │  │  ✗ Deny all     ││
│  │  ✗ Deny all other    │  │                      │  │    other        ││
│  │                      │  │                      │  │                 ││
│  │  Service Endpoints:  │  │  Service Endpoints:  │  │  Service        ││
│  │  - Storage           │  │  - SQL               │  │  Endpoints:     ││
│  │  - Key Vault         │  │  - Storage           │  │  - SQL          ││
│  │                      │  │                      │  │                 ││
│  │  Route Table:        │  │  Route Table:        │  │  No Route Table ││
│  │  0.0.0.0/0 → Firewall│  │  0.0.0.0/0 → Firewall│  │  (No internet)  ││
│  └──────────────────────┘  └──────────────────────┘  └─────────────────┘│
│                                                                            │
│  ┌──────────────────────────────────────────────────────────────────────┐│
│  │                        snet-aks                                       ││
│  │                      10.1.10.0/23                                     ││
│  │                                                                        ││
│  │  Subnet Delegation: Microsoft.ContainerService/managedClusters        ││
│  │                                                                        ││
│  │  ┌──────────────────────────────────────────────────────────────────┐││
│  │  │ Azure Kubernetes Service (AKS) Cluster                            │││
│  │  │ - 512 IPs for nodes and pods                                      │││
│  │  │ - Service Endpoints: Storage, Container Registry                  │││
│  │  │ - CNI networking                                                  │││
│  │  └──────────────────────────────────────────────────────────────────┘││
│  │                                                                        ││
│  │  Route Table: 0.0.0.0/0 → Firewall                                    ││
│  └──────────────────────────────────────────────────────────────────────┘│
│                                                                            │
└───────────────────────────────────────────────────────────────────────────┘
                                    ▲
                                    │
                              VNet Peering
                        UseRemoteGateways = true
                      AllowForwardedTraffic = true
                                    │
                                    ▼
┌───────────────────────────────────────────────────────────────────────────┐
│                           HUB VIRTUAL NETWORK                              │
│                              10.0.0.0/16                                   │
│                                                                            │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────────────────┐ │
│  │ Azure Firewall  │  │ Azure Bastion   │  │ VPN Gateway              │ │
│  │  10.0.1.4       │  │                 │  │ (to on-premises)         │ │
│  └─────────────────┘  └─────────────────┘  └──────────────────────────┘ │
│                                                                            │
│  Private DNS Zones: (linked to spoke via VNet peering)                    │
│  - privatelink.blob.core.windows.net                                      │
│  - privatelink.database.windows.net                                       │
│  - privatelink.vaultcore.azure.net                                        │
└───────────────────────────────────────────────────────────────────────────┘
```

## Traffic Flow Examples

### Internet-bound Traffic
```
Web VM → NSG (allow) → Route Table → Hub Firewall → Internet
10.1.1.10              0.0.0.0/0      10.0.1.4      App Rules
```

### Internal Traffic (Frontend → Application)
```
Frontend VM → NSG (allow) → Same VNet → Application VM
10.1.1.10     src: 10.1.1.0/24         10.1.2.20
```

### Database Access via Private Endpoint
```
App VM → Private Endpoint → Azure SQL Database
10.1.2.20  10.1.3.5        (over Azure backbone)
           (no internet)
```

### Management Access
```
Admin → Azure Bastion → Hub → Spoke VM
        (via hub)      Peering  10.1.x.x
```

## Features

### Automatic Hub Peering
- Bi-directional VNet peering automatically configured
- `UseRemoteGateways` enabled for VPN/ExpressRoute transit
- `AllowForwardedTraffic` enabled for hub firewall routing

### Network Security
- **Default Deny NSGs**: All subnets get NSG with deny-all default rule
- **Custom Security Rules**: Define allowed traffic per subnet
- **NSG Flow Logs**: Automatic flow logging with Traffic Analytics
- **Service Endpoints**: Configure per-subnet for Azure PaaS services

### Flexible Routing
- **Automatic Default Route**: 0.0.0.0/0 → Hub Firewall
- **RFC1918 Routes**: Private IP ranges route through firewall
- **Custom Routes**: Add your own routes as needed
- **Per-Subnet Control**: Disable route table for subnets that don't need it

### Private Endpoints
- **Automated Creation**: Define private endpoints in configuration
- **DNS Integration**: Automatic private DNS zone integration
- **Multi-Service Support**: SQL, Storage, Key Vault, etc.

### Subnet Delegation
- **AKS Support**: Delegate subnets to Azure Kubernetes Service
- **App Service**: Delegate to App Service for VNet integration
- **Other Services**: Support for all Azure subnet delegations

## Usage

### Basic Three-Tier Web App

```hcl
module "spoke_network" {
  source = "./modules/spoke-network"

  resource_group_name = "rg-webapp-prd-eus"
  location            = "eastus"
  environment         = "prod"
  workload_name       = "webapp"

  spoke_address_space = ["10.1.0.0/16"]

  subnets = {
    "snet-frontend" = {
      address_prefix    = "10.1.1.0/24"
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
      security_rules = [
        {
          name                       = "AllowHTTPS"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          destination_port_range     = "443"
          source_address_prefix      = "Internet"
          destination_address_prefix = "*"
        }
      ]
    }
    
    "snet-application" = {
      address_prefix    = "10.1.2.0/24"
      service_endpoints = ["Microsoft.Sql"]
    }
    
    "snet-database" = {
      address_prefix                            = "10.1.3.0/24"
      private_endpoint_network_policies_enabled = false
      associate_route_table                     = false  # No internet needed
    }
  }

  # Hub Configuration
  hub_vnet_id             = module.hub_network.hub_vnet_id
  hub_vnet_name           = module.hub_network.hub_vnet_name
  hub_resource_group_name = "rg-network-hub-prd-eus"
  hub_firewall_private_ip = module.hub_network.firewall_private_ip
  use_remote_gateways     = true

  # Monitoring
  network_watcher_name                = "NetworkWatcher_eastus"
  network_watcher_resource_group_name = "NetworkWatcherRG"
  flow_logs_storage_account_id        = module.hub_network.flow_logs_storage_account_id
  log_analytics_workspace_id          = var.log_analytics_workspace_id

  tags = {
    Application = "customer-portal"
    CostCenter  = "APP-001"
  }
}
```

### AKS Workload with Subnet Delegation

```hcl
module "spoke_network" {
  source = "./modules/spoke-network"

  # ... basic configuration ...

  subnets = {
    "snet-aks-nodes" = {
      address_prefix    = "10.2.0.0/23"  # 512 IPs for AKS
      service_endpoints = ["Microsoft.Storage", "Microsoft.ContainerRegistry"]
      
      delegation = {
        name         = "aks-delegation"
        service_name = "Microsoft.ContainerService/managedClusters"
        actions = [
          "Microsoft.Network/virtualNetworks/subnets/join/action"
        ]
      }
    }
    
    "snet-app-service" = {
      address_prefix    = "10.2.2.0/24"
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]
      
      delegation = {
        name         = "appservice-delegation"
        service_name = "Microsoft.Web/serverFarms"
        actions = [
          "Microsoft.Network/virtualNetworks/subnets/action"
        ]
      }
    }
  }
}
```

### With Private Endpoints

```hcl
module "spoke_network" {
  source = "./modules/spoke-network"

  # ... basic configuration ...

  private_endpoints = {
    "sql-database" = {
      subnet_name                    = "snet-database"
      private_connection_resource_id = azurerm_mssql_server.main.id
      subresource_names              = ["sqlServer"]
      private_dns_zone_ids = [
        module.hub_network.private_dns_zone_ids["sql"]
      ]
    }
    
    "storage-blob" = {
      subnet_name                    = "snet-database"
      private_connection_resource_id = azurerm_storage_account.main.id
      subresource_names              = ["blob"]
      private_dns_zone_ids = [
        module.hub_network.private_dns_zone_ids["blob"]
      ]
    }
    
    "key-vault" = {
      subnet_name                    = "snet-database"
      private_connection_resource_id = azurerm_key_vault.main.id
      subresource_names              = ["vault"]
      private_dns_zone_ids = [
        module.hub_network.private_dns_zone_ids["keyvault"]
      ]
    }
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | ~> 3.80 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| resource_group_name | Name of the resource group | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| environment | Environment name | `string` | n/a | yes |
| workload_name | Name of the workload | `string` | n/a | yes |
| spoke_address_space | Spoke VNet address space | `list(string)` | n/a | yes |
| subnets | Map of subnets to create | `map(object)` | n/a | yes |
| hub_vnet_id | ID of hub VNet to peer with | `string` | n/a | yes |
| hub_vnet_name | Name of hub VNet | `string` | n/a | yes |
| hub_resource_group_name | Hub resource group name | `string` | n/a | yes |
| hub_firewall_private_ip | Hub firewall private IP | `string` | `null` | no |
| use_remote_gateways | Use remote gateways | `bool` | `true` | no |
| private_endpoints | Map of private endpoints | `map(object)` | `{}` | no |
| enable_nsg_flow_logs | Enable NSG flow logs | `bool` | `true` | no |

See [variables.tf](variables.tf) for complete list.

## Outputs

| Name | Description |
|------|-------------|
| spoke_vnet_id | ID of spoke VNet |
| subnet_ids | Map of subnet IDs |
| nsg_ids | Map of NSG IDs |
| route_table_id | ID of route table |
| private_endpoint_ids | Map of private endpoint IDs |

See [outputs.tf](outputs.tf) for complete list.

## Examples

- [Web Application Spoke](examples/webapp-spoke.tfvars)

## Best Practices

### Subnet Sizing

Use these guidelines for subnet sizing:

- **Web/Frontend**: /24 (254 IPs) - sufficient for load balancers + scale sets
- **Application**: /24 (254 IPs) - room for horizontal scaling
- **Database**: /26 (62 IPs) - private endpoints don't need many IPs
- **AKS**: /23 or /22 - AKS needs many IPs for nodes and pods
- **App Service**: /26 minimum - required for VNet integration

### Security Rules

- **Start with Deny All**: Default NSG denies everything
- **Add Only What's Needed**: Least privilege principle
- **Use Service Tags**: Prefer `Internet`, `VirtualNetwork` over IP ranges
- **Document with Descriptions**: Every rule should have a description

### Route Table Decisions

- **Frontend/App Tiers**: Associate route table (need internet via firewall)
- **Database Tier**: No route table (private endpoints only, no internet)
- **AKS**: Associate route table (pods need internet for updates)

### Service Endpoints vs Private Endpoints

- **Service Endpoints**: Free, faster, but traffic stays on Azure backbone
- **Private Endpoints**: Cost ~$7/month, get private IP, better for zero-trust
- **Recommendation**: Use private endpoints for production databases and storage

## Cost Estimates (Monthly)

| Component | Quantity | Est. Cost (USD) |
|-----------|----------|-----------------|
| VNet Peering (inbound) | 1 | $0 (first 5GB free) |
| VNet Peering (outbound) | Depends on traffic | $0.01/GB |
| Private Endpoints | 3 | $21 ($7 each) |
| NSG Flow Logs Storage | 1 | $20-50 |
| **Total** | | **~$50-75/mo** |

*Additional costs for data transfer between regions or to internet.*

## Troubleshooting

### VNet Peering Not Working

Check peering status:
```bash
az network vnet peering show \
  --resource-group rg-webapp-prd-eus \
  --vnet-name vnet-webapp-prd-eus \
  --name peer-spoke-to-hub
```

Peering state should be `Connected`.

### Can't Reach Hub Resources

Ensure `AllowForwardedTraffic` is `true` on both peerings.

### Private Endpoint DNS Not Resolving

Check private DNS zone VNet link:
```bash
az network private-dns link vnet list \
  --resource-group rg-network-hub-prd-eus \
  --zone-name privatelink.database.windows.net
```

### Route Table Not Working

Verify route:
```bash
az network route-table route list \
  --resource-group rg-webapp-prd-eus \
  --route-table-name rt-webapp-prd-eus
```

## License

MIT

## Authors

Cloud Platform Team
