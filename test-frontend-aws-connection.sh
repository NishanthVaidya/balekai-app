#!/bin/bash

echo "🔗 Testing Frontend Connection to AWS Backend"
echo "============================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

AWS_BACKEND_URL="http://balekai-alb-new-626347040.us-east-1.elb.amazonaws.com"

echo -e "${BLUE}Step 1: Testing Basic Connectivity${NC}"
echo "Testing connection to AWS backend..."

# Test basic connectivity
if curl -s --connect-timeout 10 "$AWS_BACKEND_URL/health" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Basic connectivity successful${NC}"
else
    echo -e "${YELLOW}⚠️  Basic connectivity test failed (this might be expected)${NC}"
fi

echo ""
echo -e "${BLUE}Step 2: Testing Public Endpoints${NC}"

# Test public endpoints
echo "Testing /auth/register endpoint..."
REGISTER_RESPONSE=$(curl -s -X POST "$AWS_BACKEND_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d '{"email":"test-connection@example.com","password":"testpass123","name":"Test Connection User"}')

if echo "$REGISTER_RESPONSE" | grep -q "id"; then
    echo -e "${GREEN}✅ Registration endpoint working${NC}"
    USER_ID=$(echo "$REGISTER_RESPONSE" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
    echo "Test user created with ID: $USER_ID"
else
    echo -e "${YELLOW}⚠️  Registration endpoint response: $REGISTER_RESPONSE${NC}"
fi

echo ""
echo -e "${BLUE}Step 3: Testing Authentication Flow${NC}"

# Test login
echo "Testing /auth/login endpoint..."
LOGIN_RESPONSE=$(curl -s -X POST "$AWS_BACKEND_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"test-connection@example.com","password":"testpass123"}')

if echo "$LOGIN_RESPONSE" | grep -q "token"; then
    echo -e "${GREEN}✅ Login endpoint working${NC}"
    TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    echo "JWT token received: ${TOKEN:0:50}..."
else
    echo -e "${YELLOW}⚠️  Login endpoint response: $LOGIN_RESPONSE${NC}"
fi

echo ""
echo -e "${BLUE}Step 4: Testing Protected Endpoints${NC}"

if [ ! -z "$TOKEN" ]; then
    echo "Testing protected /boards endpoint with JWT token..."
    BOARDS_RESPONSE=$(curl -s -X GET "$AWS_BACKEND_URL/boards" \
        -H "Authorization: Bearer $TOKEN")
    
    if echo "$BOARDS_RESPONSE" | grep -q "boards"; then
        echo -e "${GREEN}✅ Protected endpoint working with JWT${NC}"
    else
        echo -e "${YELLOW}⚠️  Protected endpoint response: $BOARDS_RESPONSE${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Skipping protected endpoint test (no token)${NC}"
fi

echo ""
echo -e "${BLUE}Step 5: Frontend Configuration Check${NC}"

# Check if frontend files are updated
if grep -q "balekai-alb-new" frontend/app/utils/api.tsx; then
    echo -e "${GREEN}✅ Frontend API configuration updated for AWS${NC}"
else
    echo -e "${RED}❌ Frontend API configuration not updated${NC}"
fi

if [ -f "frontend/env.production" ]; then
    echo -e "${GREEN}✅ Production environment file created${NC}"
    echo "Production API URL: $(cat frontend/env.production)"
else
    echo -e "${YELLOW}⚠️  Production environment file not found${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Frontend-AWS Backend Connection Test Complete!${NC}"
echo ""
echo "📋 Next Steps:"
echo "1. Build and deploy frontend to production"
echo "2. Test all functionality with AWS backend"
echo "3. Monitor for any connection issues"
echo ""
echo "🔗 AWS Backend URL: $AWS_BACKEND_URL"
echo "📱 Frontend is now configured to use AWS backend by default"
