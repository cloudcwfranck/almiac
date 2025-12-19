#!/bin/bash
set -euo pipefail

# What-If Analysis for Hub Network
# Usage: ./whatif-hub.sh <environment> <cloud-type>
# Example: ./whatif-hub.sh dev commercial

ENVIRONMENT=${1:-dev}
CLOUD_TYPE=${2:-commercial}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARAM_FILE="${SCRIPT_DIR}/../parameters/hub-network/${ENVIRONMENT}-${CLOUD_TYPE}.bicepparam"
BICEP_FILE="${SCRIPT_DIR}/../modules/hub-network/main.bicep"

echo "======================================"
echo "What-If Analysis: Hub Network"
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

echo "Running what-if analysis..."
az deployment sub what-if \
    --name "whatif-hub-${ENVIRONMENT}" \
    --location eastus \
    --template-file "${BICEP_FILE}" \
    --parameters "${PARAM_FILE}"

echo "======================================"
echo "What-If analysis completed!"
echo "======================================"
