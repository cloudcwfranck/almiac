#!/bin/bash
set -euo pipefail

# Build all Bicep files to ARM templates
# Usage: ./build-all.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_DIR="${SCRIPT_DIR}/../modules"
OUTPUT_DIR="${SCRIPT_DIR}/../build"

echo "======================================"
echo "Building All Bicep Modules to ARM"
echo "======================================"

# Create output directory
mkdir -p "${OUTPUT_DIR}/hub-network"
mkdir -p "${OUTPUT_DIR}/spoke-network"

# Build hub network
echo "Building hub-network module..."
az bicep build \
    --file "${MODULE_DIR}/hub-network/main.bicep" \
    --outfile "${OUTPUT_DIR}/hub-network/main.json"

# Build spoke network
echo "Building spoke-network module..."
az bicep build \
    --file "${MODULE_DIR}/spoke-network/main.bicep" \
    --outfile "${OUTPUT_DIR}/spoke-network/main.json"

echo "======================================"
echo "Build completed!"
echo "ARM templates saved to: ${OUTPUT_DIR}"
echo "======================================"
