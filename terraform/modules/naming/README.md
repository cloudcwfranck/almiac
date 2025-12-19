# CAF Naming Module

This module generates Azure resource names following the Cloud Adoption Framework (CAF) naming conventions.

## Naming Convention

The module follows the pattern:
```
{resourceType}-{workload}-{environment}-{region}-{instance}
```

### Examples:
- `vnet-hub-prod-eus-001` - Hub virtual network in production East US
- `law-monitor-prod-eus-001` - Log Analytics workspace for monitoring
- `kv-secrets-prod-eus-001` - Key Vault for secrets
- `stdiagprodeus001` - Storage account for diagnostics (no hyphens)

## Usage

```hcl
module "naming" {
  source = "../../modules/naming"
  
  workload_name   = "hub"
  environment     = "prod"
  location        = "eastus"
  instance_number = 1
}

resource "azurerm_virtual_network" "example" {
  name                = module.naming.virtual_network_name
  resource_group_name = module.naming.resource_group_name
  location            = var.location
  address_space       = ["10.0.0.0/16"]
  
  tags = module.naming.tags
}
```

## Special Rules

### Storage Accounts
- No hyphens allowed
- Lowercase letters and numbers only
- 3-24 characters
- Globally unique

### Key Vault
- 3-24 characters
- Alphanumerics and hyphens
- Must start with a letter
- Globally unique

### Container Registry
- 5-50 characters
- Alphanumeric only
- Globally unique

### Virtual Machines (Windows)
- Maximum 15 characters
- Set `os_type = "windows"` to enforce this limit

## Variables

| Name | Description | Type | Required |
|------|-------------|------|----------|
| workload_name | Name of the workload or application | string | yes |
| environment | Environment (dev, staging, prod) | string | yes |
| location | Azure region | string | yes |
| instance_number | Instance number (001, 002, etc.) | number | no |
| custom_prefix | Custom prefix for resource names | string | no |
| os_type | OS type for VM naming (windows/linux) | string | no |

## Outputs

The module provides individual outputs for each resource type:
- `resource_group_name`
- `virtual_network_name`
- `subnet_name`
- And many more...

Plus a grouped output:
- `names` - Map of all resource names
- `tags` - Standard tags based on naming convention
- `common` - Common naming components
