#!/bin/bash

echo "🔧 Fixing UserController Authentication Issues"
echo "=============================================="

echo "Step 1: Force ECS Service Update"
aws ecs update-service \
    --cluster balekai-cluster \
    --service balekai-service \
    --force-new-deployment \
    --region us-east-1

echo "Step 2: Wait for deployment to complete"
aws ecs wait services-stable \
    --cluster balekai-cluster \
    --services balekai-service \
    --region us-east-1

echo "Step 3: Test the fixed endpoints"
echo "Testing /users endpoint with authentication..."

# Test with a fresh token
TOKEN=$(curl -s -X POST "https://dtcvfgct9ga1.cloudfront.net/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"testuser@example.com","password":"password123"}' | \
    jq -r '.accessToken')

if [ "$TOKEN" != "null" ] && [ "$TOKEN" != "" ]; then
    echo "✅ Login successful, testing /users endpoint..."
    curl -X GET "https://dtcvfgct9ga1.cloudfront.net/users" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Origin: https://www.balekai.com" \
        -v
else
    echo "❌ Login failed, checking if user exists..."
    curl -X POST "https://dtcvfgct9ga1.cloudfront.net/auth/register" \
        -H "Content-Type: application/json" \
        -d '{"name":"Test User","email":"testuser@example.com","password":"password123"}' \
        -v
fi

echo "🎉 UserController authentication fix completed!"
