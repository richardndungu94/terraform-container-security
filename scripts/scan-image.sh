#!/bin/bash
# scripts/scan-image.sh
# Scan container image locally before pushing

set -e

echo "=========================================="
echo "Local Container Security Scan"
echo "=========================================="
echo ""

# Check if Trivy is installed
if ! command -v trivy &> /dev/null; then
    echo "Installing Trivy..."
    curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
fi

# Get image name from argument or prompt
if [ -z "$1" ]; then
    read -p "Enter image name to scan: " IMAGE_NAME
else
    IMAGE_NAME=$1
fi

echo ""
echo "🔍 Scanning image: $IMAGE_NAME"
echo ""

# Scan for vulnerabilities
echo "1. Scanning for vulnerabilities..."
trivy image --severity CRITICAL,HIGH $IMAGE_NAME

echo ""
echo "2. Scanning for misconfigurations..."
trivy image --scanners config $IMAGE_NAME

echo ""
echo "3. Scanning for secrets..."
trivy image --scanners secret $IMAGE_NAME

echo ""
echo "=========================================="
echo "✅ Scan complete!"
echo ""
echo "💡 To fix vulnerabilities:"
echo "  - Update base image"
echo "  - Update dependencies in requirements.txt"
echo "  - Rebuild image"
echo "=========================================="
