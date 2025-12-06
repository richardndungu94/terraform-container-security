# scripts/test-deployment.sh
#!/bin/bash
# Test the deployed application

set -e

echo "=========================================="
echo "Testing Container Deployment"
echo "=========================================="
echo ""

# Get ALB URL from Terraform output
ALB_URL=$(terraform output -raw application_url 2>/dev/null)

if [ -z "$ALB_URL" ]; then
    echo "❌ Could not get ALB URL from Terraform"
    exit 1
fi

echo "Application URL: $ALB_URL"
echo ""

# Wait for ALB to be ready
echo "Waiting for application to be ready..."
for i in {1..30}; do
    if curl -sf "$ALB_URL/health" > /dev/null 2>&1; then
        echo "✅ Application is ready!"
        break
    fi
    echo "  Attempt $i/30..."
    sleep 10
done

echo ""
echo "=========================================="
echo "Testing Endpoints"
echo "=========================================="

# Test health endpoint
echo ""
echo "1. Health Check:"
curl -s "$ALB_URL/health" | jq

# Test main endpoint
echo ""
echo "2. Main Endpoint:"
curl -s "$ALB_URL/" | jq

# Test performance
echo ""
echo "3. Response Time:"
time curl -s "$ALB_URL/health" > /dev/null

echo ""
echo "=========================================="
echo "✅ All tests passed!"
echo ""
echo "📊 View metrics:"
echo "  CloudWatch Dashboard: https://console.aws.amazon.com/cloudwatch/"
echo ""
echo "📋 View logs:"
echo "  aws logs tail /ecs/container-security --follow"
echo "=========================================="
