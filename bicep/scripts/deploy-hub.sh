#!/bin/bash
set -euo pipefail

# Deploy Hub Network
# Usage: ./deploy-hub.sh <environment> <cloud-type>
# Example: ./deploy-hub.sh dev commercial

ENVIRONMENT=${1:-dev}
CLOUD_TYPE=${2:-commercial}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARAM_FILE="${SCRIPT_DIR}/../parameters/hub-network/${ENVIRONMENT}-${CLOUD_TYPE}.bicepparam"
BICEP_FILE="${SCRIPT_DIR}/../modules/hub-network/main.bicep"

echo "======================================"
echo "Deploying Hub Network"
echo "Environment: ${ENVIRONMENT}"
echo "Cloud Type: ${CLOUD_TYPE}"
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
DEPLOYMENT_NAME="hub-network-${ENVIRONMENT}-$(date +%Y%m%d-%H%M%S)"
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
