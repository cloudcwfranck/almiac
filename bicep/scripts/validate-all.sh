#!/bin/bash
set -euo pipefail

# Validate all Bicep modules
# Usage: ./validate-all.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_DIR="${SCRIPT_DIR}/../modules"

echo "======================================"
echo "Validating All Bicep Modules"
echo "======================================"

# Find all main.bicep files
BICEP_FILES=$(find "${MODULE_DIR}" -name "*.bicep" -type f)

FAILED_FILES=()
SUCCESS_COUNT=0
FAIL_COUNT=0

for FILE in ${BICEP_FILES}; do
    echo "Validating: ${FILE}"

    if az bicep build --file "${FILE}" --stdout > /dev/null 2>&1; then
        echo "✓ ${FILE} - Valid"
        ((SUCCESS_COUNT++))
    else
        echo "✗ ${FILE} - Failed"
        FAILED_FILES+=("${FILE}")
        ((FAIL_COUNT++))
    fi
    echo ""
done

echo "======================================"
echo "Validation Summary"
echo "======================================"
echo "Total Files: $((SUCCESS_COUNT + FAIL_COUNT))"
echo "Success: ${SUCCESS_COUNT}"
echo "Failed: ${FAIL_COUNT}"

if [[ ${FAIL_COUNT} -gt 0 ]]; then
    echo ""
    echo "Failed files:"
    for FILE in "${FAILED_FILES[@]}"; do
        echo "  - ${FILE}"
    done
    exit 1
fi

echo "======================================"
echo "All modules validated successfully!"
echo "======================================"
