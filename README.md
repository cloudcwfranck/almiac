# Azure Landing Zone Automation Framework (ALMIAC)

Enterprise-grade Infrastructure as Code (IaC) solution for deploying Azure Landing Zones with comprehensive compliance, security, and governance controls.

## Overview

ALMIAC provides a complete, production-ready Azure Landing Zone implementation supporting both Azure Commercial and Azure Government clouds. Choose between Terraform or Bicep based on your organization's preferences.

## Key Features

- **Dual Implementation**: Complete parity between Terraform and Bicep
- **Multi-Cloud Support**: Azure Commercial and Azure Government
- **Compliance Ready**: CIS, NIST 800-53, FedRAMP, Azure Security Benchmark, ISO 27001, SOC 2
- **Hub-Spoke Topology**: Enterprise-grade network architecture with Azure Firewall or NVA options
- **Cost Governance**: Built-in budgets, tagging standards, and cost allocation
- **Security Baseline**: Comprehensive Azure Policy implementation and security monitoring
- **Multi-Environment**: Dev, Staging, Production environment configurations
- **CI/CD Ready**: GitHub Actions workflows with security scanning

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Management Subscription                       │
│  • Log Analytics Workspace    • Azure Monitor                   │
│  • Automation Accounts        • Backup Vaults                   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    Identity Subscription                         │
│  • Azure AD Integration       • Privileged Identity Management  │
│  • RBAC Role Assignments      • Conditional Access             │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                  Connectivity Subscription                       │
│                         (Hub VNet)                              │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Firewall  │  │   Bastion    │  │  VPN/ExpressR│          │
│  │   Subnet    │  │   Subnet     │  │  oute Gateway│          │
│  └─────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘
           │                  │                  │
           └──────────────────┴──────────────────┘
                              │
      ┌───────────────────────┼───────────────────────┐
      │                       │                       │
┌─────▼──────┐      ┌────────▼─────┐      ┌─────────▼────┐
│  Landing   │      │   Landing    │      │   Landing    │
│  Zone 1    │      │   Zone 2     │      │   Zone 3     │
│ (Spoke)    │      │  (Spoke)     │      │  (Spoke)     │
└────────────┘      └──────────────┘      └──────────────┘
```

## Project Structure

```
almiac/
├── terraform/                  # Terraform implementation
│   ├── modules/               # Reusable Terraform modules
│   │   ├── networking/        # Hub-spoke network topology
│   │   ├── monitoring/        # Log Analytics, monitoring
│   │   ├── identity/          # RBAC, Azure AD integration
│   │   ├── policy/            # Azure Policy definitions
│   │   ├── security/          # Security Center, Key Vault
│   │   ├── governance/        # Cost management, tagging
│   │   └── naming/            # CAF naming conventions
│   ├── environments/          # Environment-specific configurations
│   │   ├── dev/
│   │   ├── staging/
│   │   └── prod/
│   ├── policies/              # Compliance policy definitions
│   │   ├── cis/
│   │   ├── nist-800-53/
│   │   └── fedramp/
│   └── bootstrap/             # Initial setup scripts
│
├── bicep/                     # Bicep implementation
│   ├── modules/               # Reusable Bicep modules
│   ├── environments/          # Environment-specific configurations
│   └── policies/              # Compliance policy definitions
│
├── .github/
│   └── workflows/             # CI/CD pipelines
│       ├── terraform-plan.yml
│       ├── terraform-apply.yml
│       ├── bicep-validate.yml
│       └── security-scan.yml
│
├── docs/                      # Documentation
│   ├── architecture/
│   ├── deployment/
│   ├── compliance/
│   └── operations/
│
├── scripts/                   # Helper scripts
│   ├── setup/
│   └── utilities/
│
└── config/                    # Configuration files
    ├── naming-conventions.yaml
    ├── tagging-standards.yaml
    └── rbac-assignments.yaml
```

## Quick Start

### Prerequisites

- Azure CLI 2.50+ or Azure PowerShell
- Terraform 1.5+ OR Azure Bicep 0.20+
- Git
- GitHub account (for CI/CD)
- Azure subscription(s) with appropriate permissions

### Terraform Deployment

```bash
# 1. Clone repository
git clone https://github.com/your-org/almiac.git
cd almiac

# 2. Configure Azure credentials
az login
az account set --subscription "your-subscription-id"

# 3. Initialize backend storage
cd terraform/bootstrap
terraform init
terraform apply

# 4. Deploy management subscription
cd ../environments/prod/management
terraform init
terraform plan
terraform apply

# 5. Deploy connectivity (hub)
cd ../connectivity
terraform init
terraform plan
terraform apply

# 6. Deploy landing zones (spokes)
cd ../landing-zones/workload-01
terraform init
terraform plan
terraform apply
```

### Bicep Deployment

```bash
# 1. Clone repository
git clone https://github.com/your-org/almiac.git
cd almiac

# 2. Configure Azure credentials
az login
az account set --subscription "your-subscription-id"

# 3. Deploy management subscription
cd bicep/environments/prod
az deployment sub create \
  --location eastus \
  --template-file management.bicep \
  --parameters management.parameters.json

# 4. Deploy connectivity (hub)
az deployment sub create \
  --location eastus \
  --template-file connectivity.bicep \
  --parameters connectivity.parameters.json
```

## Compliance Frameworks

### Supported Standards

- **CIS Azure Foundations Benchmark v2.0**: Complete implementation of CIS controls
- **NIST 800-53 Rev 5**: FedRAMP Moderate and High baselines
- **Azure Security Benchmark**: Microsoft's security recommendations
- **ISO 27001**: Information security management controls
- **SOC 2**: Service organization controls

### Policy Implementation

All compliance policies are implemented as Azure Policy initiatives and can be assigned at Management Group, Subscription, or Resource Group scope.

## Configuration

### Naming Conventions

Following Cloud Adoption Framework (CAF) standards:

```
{resourceType}-{workload}-{environment}-{region}-{instance}

Examples:
- vnet-hub-prod-eus-001
- law-monitor-prod-eus-001
- kv-secrets-prod-eus-001
```

### Tagging Standards

Required tags for all resources:

- `Environment`: dev, staging, prod
- `CostCenter`: Cost allocation code
- `Owner`: Team or individual responsible
- `Application`: Application name
- `Criticality`: Low, Medium, High, Mission-Critical
- `DataClassification`: Public, Internal, Confidential, Restricted
- `Compliance`: CIS, NIST, FedRAMP, etc.

## Cloud Support

### Azure Commercial

- All Azure regions supported
- Standard SKUs and services
- Azure AD authentication

### Azure Government

- US Gov regions: Virginia, Texas, Arizona
- Government-specific compliance requirements
- Azure Government AD authentication
- ITAR and FedRAMP High support

## Security Features

- **Network Security**: NSGs, Azure Firewall, DDoS Protection
- **Identity & Access**: Azure AD, RBAC, Conditional Access, PIM
- **Data Protection**: Encryption at rest and in transit, Key Vault
- **Threat Protection**: Microsoft Defender for Cloud, Sentinel
- **Compliance**: Azure Policy, Security Center, Compliance Manager
- **Monitoring**: Log Analytics, Azure Monitor, Alerts

## Cost Optimization

- Resource tagging for cost allocation
- Azure Budgets with alerts
- Right-sizing recommendations
- Reserved Instances guidance
- Cost analysis and reporting

## CI/CD Integration

GitHub Actions workflows for:

- **Validation**: Syntax checking, linting, security scanning
- **Planning**: Terraform plan / Bicep what-if
- **Deployment**: Automated or manual approval gates
- **Testing**: Compliance and security testing
- **Documentation**: Auto-generated documentation

## Support and Contributions

### Getting Help

- Review documentation in `/docs`
- Check existing GitHub issues
- Create new issue with detailed description

### Contributing

1. Fork the repository
2. Create feature branch
3. Make changes with tests
4. Submit pull request
5. Pass CI/CD checks

## License

MIT License - See LICENSE file for details

## Authors

Enterprise Cloud Architecture Team

## Version History

- **v1.0.0** (2025-12): Initial release
  - Terraform and Bicep implementations
  - CIS, NIST 800-53, FedRAMP compliance
  - Hub-spoke topology
  - Multi-environment support

## Additional Resources

- [Azure Landing Zones Documentation](https://docs.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/)
- [Cloud Adoption Framework](https://docs.microsoft.com/azure/cloud-adoption-framework/)
- [Azure Policy Samples](https://github.com/Azure/azure-policy)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Bicep Documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
