# Terraform Bootstrap

This directory contains the Terraform configuration to bootstrap the Azure infrastructure for storing Terraform state.

## What it creates

- Resource Group for Terraform state
- Storage Account with versioning and soft delete
- Storage Container for state files
- Network rules for security
- Optional Log Analytics for diagnostics
- Optional Key Vault for secrets

## Usage

### Initial Setup

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "your-subscription-id"

# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Apply configuration
terraform apply
```

### After Bootstrap

Once the bootstrap is complete, copy the backend configuration from the output and add it to your main Terraform configurations:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstatexxxxxx"
    container_name       = "tfstate"
    key                  = "prod/terraform.tfstate"
  }
}
```

### Azure Government

For Azure Government cloud:

```bash
terraform apply -var="azure_environment=usgovernment" -var="location=usgovvirginia"
```

## Security Features

- Storage account uses TLS 1.2 minimum
- Blob versioning enabled
- Soft delete enabled (30 days retention)
- No public blob access
- Network rules restrict access
- System-assigned managed identity
- Optional diagnostics logging

## State File Naming

Use different state file keys for different environments:

- Development: `dev/terraform.tfstate`
- Staging: `staging/terraform.tfstate`
- Production: `prod/terraform.tfstate`
