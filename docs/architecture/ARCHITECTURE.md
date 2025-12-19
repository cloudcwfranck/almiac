# Architecture Overview

## Landing Zone Design

This framework implements the Microsoft Cloud Adoption Framework (CAF) Landing Zone architecture.

## Subscription Organization

### Management Subscription
- Log Analytics workspace
- Automation accounts  
- Azure Monitor
- Backup vaults

### Identity Subscription
- Azure AD integration
- RBAC role assignments
- Managed identities
- Privileged Identity Management

### Connectivity Subscription
- Hub virtual network
- Azure Firewall
- Azure Bastion
- VPN/ExpressRoute gateways
- DNS zones

### Landing Zone Subscriptions
- Spoke virtual networks
- Application resources
- Data services
- Peered to hub

## Network Topology

### Hub Network (10.0.0.0/16)
```
├── Firewall Subnet (10.0.1.0/24)
│   └── Azure Firewall
├── Bastion Subnet (10.0.2.0/24)
│   └── Azure Bastion
├── Gateway Subnet (10.0.3.0/24)
│   ├── VPN Gateway
│   └── ExpressRoute Gateway
└── Management Subnet (10.0.4.0/24)
    └── Jump servers
```

### Spoke Networks (10.x.0.0/16)
```
├── Web Subnet (10.x.1.0/24)
├── App Subnet (10.x.2.0/24)
└── Data Subnet (10.x.3.0/24)
```

## Traffic Flow

1. **Ingress**: Internet → Firewall → Application Gateway → Web Tier
2. **East-West**: Spoke → Hub Firewall → Spoke
3. **Egress**: Application → Hub Firewall → Internet
4. **On-Premises**: VPN/ER Gateway → Hub → Spokes

## Security Layers

1. **Network**: Firewall, NSGs, ASGs
2. **Identity**: Azure AD, RBAC, PIM
3. **Application**: WAF, DDoS, TLS
4. **Data**: Encryption, Key Vault, Private Endpoints
5. **Monitoring**: Log Analytics, Sentinel, Defender

## Compliance

- Policy enforcement at subscription/resource group level
- Audit logs centralized in Log Analytics
- Compliance dashboards in Azure Portal
- Automated remediation via Azure Policy
