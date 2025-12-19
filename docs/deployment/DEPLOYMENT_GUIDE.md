# Azure Landing Zone Deployment Guide

This guide provides step-by-step instructions for deploying the Azure Landing Zone Automation Framework.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Bootstrap Terraform State](#bootstrap-terraform-state)
4. [Deploy Management Subscription](#deploy-management-subscription)
5. [Deploy Connectivity (Hub)](#deploy-connectivity-hub)
6. [Deploy Landing Zones (Spokes)](#deploy-landing-zones-spokes)
7. [Post-Deployment](#post-deployment)
8. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Tools

- **Azure CLI**: Version 2.50 or later
  ```bash
  az --version
  ```

- **Terraform**: Version 1.5 or later
  ```bash
  terraform --version
  ```

- **Git**: For source control
  ```bash
  git --version
  ```

### Azure Permissions

You need the following permissions:

- **Owner** role at the Management Group or Subscription level
- Ability to create Azure AD groups
- Ability to create service principals

### Azure AD Groups

Create the following Azure AD groups before deployment:

```bash
# Platform Teams
az ad group create --display-name "AZ-PLATFORM-ADMINS" --mail-nickname "az-platform-admins"
az ad group create --display-name "AZ-NETWORK-ADMINS" --mail-nickname "az-network-admins"
az ad group create --display-name "AZ-SECURITY-ADMINS" --mail-nickname "az-security-admins"
az ad group create --display-name "AZ-MONITORING-ADMINS" --mail-nickname "az-monitoring-admins"

# Workload Teams
az ad group create --display-name "AZ-WORKLOAD-WEBAPP-ADMINS" --mail-nickname "az-workload-webapp-admins"
```

## Initial Setup

### 1. Clone Repository

```bash
git clone https://github.com/your-org/almiac.git
cd almiac
```

### 2. Configure Azure CLI

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "your-subscription-id"

# Verify
az account show
```

### 3. Create Service Principal for Terraform

```bash
# Create service principal
az ad sp create-for-rbac \
  --name "sp-terraform-automation" \
  --role Owner \
  --scopes /subscriptions/{subscription-id}

# Save output - you'll need:
# - appId (CLIENT_ID)
# - password (CLIENT_SECRET)
# - tenant (TENANT_ID)
```

### 4. Set Environment Variables

```bash
export ARM_CLIENT_ID="your-app-id"
export ARM_CLIENT_SECRET="your-password"
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_TENANT_ID="your-tenant-id"
```

## Bootstrap Terraform State

### Step 1: Initialize Bootstrap

```bash
cd terraform/bootstrap
terraform init
```

### Step 2: Plan Bootstrap

```bash
terraform plan \
  -var="location=eastus" \
  -var="environment=prod" \
  -out=bootstrap.tfplan
```

### Step 3: Apply Bootstrap

```bash
terraform apply bootstrap.tfplan
```

### Step 4: Save Backend Configuration

```bash
# Terraform will output backend configuration
# Save this to a file: backend-config.tfvars

terraform output -raw backend_config_file > ../backend-config.txt
```

## Deploy Management Subscription

The management subscription hosts monitoring, logging, and automation resources.

### Step 1: Navigate to Environment

```bash
cd ../environments/prod/management
```

### Step 2: Initialize with Backend

```bash
terraform init \
  -backend-config="resource_group_name=rg-terraform-state" \
  -backend-config="storage_account_name=YOUR_STORAGE_ACCOUNT" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=prod/management/terraform.tfstate"
```

### Step 3: Plan Deployment

```bash
terraform plan -out=management.tfplan
```

Review the plan carefully. It should create:
- Resource group
- Log Analytics workspace
- Automation account
- Diagnostic storage account
- Monitoring solutions

### Step 4: Apply Deployment

```bash
terraform apply management.tfplan
```

### Step 5: Verify Deployment

```bash
# Get Log Analytics workspace
terraform output log_analytics_workspace_id

# Verify in portal
az monitor log-analytics workspace show \
  --resource-group rg-management-prod-eus-001 \
  --workspace-name law-management-prod-eus-001
```

## Deploy Connectivity (Hub)

The connectivity subscription hosts the hub virtual network with firewall, bastion, and VPN gateway.

### Step 1: Navigate to Environment

```bash
cd ../connectivity
```

### Step 2: Update Remote State Reference

Edit `main.tf` and update the storage account name in the `terraform_remote_state` data source.

### Step 3: Initialize

```bash
terraform init \
  -backend-config="resource_group_name=rg-terraform-state" \
  -backend-config="storage_account_name=YOUR_STORAGE_ACCOUNT" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=prod/connectivity/terraform.tfstate"
```

### Step 4: Plan Deployment

```bash
terraform plan -out=connectivity.tfplan
```

Review the plan. It should create:
- Hub virtual network (10.0.0.0/16)
- Azure Firewall (Premium tier)
- Azure Bastion
- VPN Gateway
- Required subnets and NSGs

### Step 5: Apply Deployment

**Note**: This deployment takes 30-45 minutes due to VPN Gateway creation.

```bash
terraform apply connectivity.tfplan
```

### Step 6: Verify Deployment

```bash
# Get hub VNet ID
terraform output hub_vnet_id

# Get firewall private IP
terraform output firewall_private_ip

# List resources
az network vnet list --resource-group rg-hub-prod-eus-001 --output table
```

## Deploy Landing Zones (Spokes)

Landing zones are spoke virtual networks for application workloads.

### Step 1: Navigate to Landing Zone

```bash
cd ../landing-zones/workload-01
```

### Step 2: Update Remote State References

Edit `main.tf` and update storage account names in both remote state data sources.

### Step 3: Initialize

```bash
terraform init \
  -backend-config="resource_group_name=rg-terraform-state" \
  -backend-config="storage_account_name=YOUR_STORAGE_ACCOUNT" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=prod/landing-zones/workload-01/terraform.tfstate"
```

### Step 4: Plan Deployment

```bash
terraform plan -out=workload.tfplan
```

Review the plan. It should create:
- Spoke virtual network (10.1.0.0/16)
- Three subnets (web, app, data)
- Network security groups
- VNet peering to hub
- Route table (routes to firewall)

### Step 5: Apply Deployment

```bash
terraform apply workload.tfplan
```

### Step 6: Verify Deployment

```bash
# Get spoke VNet ID
terraform output spoke_vnet_id

# Verify peering
az network vnet peering list \
  --resource-group rg-webapp-prod-eus-001 \
  --vnet-name vnet-webapp-prod-eus-001 \
  --output table
```

## Post-Deployment

### Assign RBAC Roles

```bash
# Get resource group ID
RG_ID=$(az group show --name rg-management-prod-eus-001 --query id -o tsv)

# Assign roles
az role assignment create \
  --assignee-object-id $(az ad group show --group "AZ-MONITORING-ADMINS" --query id -o tsv) \
  --role "Log Analytics Contributor" \
  --scope $RG_ID
```

### Configure Firewall Rules

```bash
# Navigate to Azure Portal
# Firewall > Settings > Rules

# Create application rules
# Create network rules
# Configure DNAT rules if needed
```

### Enable Microsoft Defender

```bash
# Enable Defender for Cloud
az security pricing create \
  --name VirtualMachines \
  --tier Standard

az security pricing create \
  --name SqlServers \
  --tier Standard

az security pricing create \
  --name StorageAccounts \
  --tier Standard
```

### Configure Budget Alerts

Budgets are created automatically. Verify in Azure Portal:
1. Navigate to Cost Management + Billing
2. Click on Budgets
3. Review and adjust thresholds

## Troubleshooting

### State Lock Issues

If you encounter state lock issues:

```bash
# Force unlock (use with caution)
terraform force-unlock LOCK_ID
```

### VPN Gateway Creation Timeout

VPN Gateway can take up to 45 minutes to create. If it times out:

```bash
# Check status in portal
az network vnet-gateway show \
  --name vgw-hub-prod-eus-001 \
  --resource-group rg-hub-prod-eus-001 \
  --query provisioningState
```

### Peering Failures

If VNet peering fails:

```bash
# Check peering status
az network vnet peering show \
  --name peer-spoke-to-hub \
  --resource-group rg-webapp-prod-eus-001 \
  --vnet-name vnet-webapp-prod-eus-001

# Delete and recreate
az network vnet peering delete --name peer-spoke-to-hub ...
terraform apply
```

### Module Not Found

If Terraform can't find modules:

```bash
# Reinitialize
rm -rf .terraform
terraform init
```

## Next Steps

1. **Deploy Additional Landing Zones**: Copy `workload-01` and customize for other applications
2. **Configure Firewall Rules**: Add application and network rules
3. **Set Up Monitoring**: Configure alerts and dashboards
4. **Enable Compliance Policies**: Assign CIS and NIST initiatives
5. **Configure Backup**: Enable Azure Backup for critical resources

## Support

For issues or questions:
- Review logs: `terraform show`
- Check Azure Activity Log
- Review GitHub Issues
- Contact platform team

## Resources

- [Azure Landing Zones](https://docs.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/)
- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure CAF Naming](https://docs.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging)
