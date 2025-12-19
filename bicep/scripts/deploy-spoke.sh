#!/bin/bash
set -euo pipefail

# Deploy Spoke Network
# Usage: ./deploy-spoke.sh <workload> <environment>
# Example: ./deploy-spoke.sh webapp dev

WORKLOAD=${1:-webapp}
ENVIRONMENT=${2:-dev}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARAM_FILE="${SCRIPT_DIR}/../parameters/spoke-network/${ENVIRONMENT}-${WORKLOAD}.bicepparam"
BICEP_FILE="${SCRIPT_DIR}/../modules/spoke-network/main.bicep"

echo "======================================"
echo "Deploying Spoke Network"
echo "Workload: ${WORKLOAD}"
echo "Environment: ${ENVIRONMENT}"
echo "======================================"

# Validate parameter file exists
if [[ ! -f "${PARAM_FILE}" ]]; then
    echo "Error: Parameter file not found: ${PARAM_FILE}"
    exit 1
fi

# Validate Bicep file
echo "Validating Bicep template..."
az bicep build --file "${BICEP_FILE}"

# Get subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "Using subscription: ${SUBSCRIPTION_ID}"

# Deploy
DEPLOYMENT_NAME="spoke-${WORKLOAD}-${ENVIRONMENT}-$(date +%Y%m%d-%H%M%S)"
echo "Deployment name: ${DEPLOYMENT_NAME}"

echo "Starting deployment..."
az deployment sub create \
    --name "${DEPLOYMENT_NAME}" \
    --location eastus \
    --template-file "${BICEP_FILE}" \
    --parameters "${PARAM_FILE}" \
    --verbose

echo "======================================"
echo "Deployment completed successfully!"
echo "======================================"
