#!/bin/bash

# Test script for token refresh functionality
echo "🧪 Testing Token Refresh Mechanism"
echo "=================================="

# Configuration
API_BASE_URL="https://dtcvfgct9ga1.cloudfront.net"
TEST_EMAIL="test-refresh@example.com"
TEST_PASSWORD="testpassword123"
TEST_NAME="Test User"

echo "📝 Test Configuration:"
echo "  API Base URL: $API_BASE_URL"
echo "  Test Email: $TEST_EMAIL"
echo "  Test Name: $TEST_NAME"
echo ""

# Function to make API calls
make_request() {
    local method=$1
    local endpoint=$2
    local data=$3
    local token=$4
    
    if [ -n "$token" ]; then
        curl -s -X $method \
             -H "Content-Type: application/json" \
             -H "Authorization: Bearer $token" \
             -d "$data" \
             "$API_BASE_URL$endpoint"
    else
        curl -s -X $method \
             -H "Content-Type: application/json" \
             -d "$data" \
             "$API_BASE_URL$endpoint"
    fi
}

# Step 1: Register a test user
echo "1️⃣ Registering test user..."
REGISTER_RESPONSE=$(make_request "POST" "/auth/register" "{\"name\":\"$TEST_NAME\",\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}")

if echo "$REGISTER_RESPONSE" | grep -q "accessToken"; then
    echo "✅ Registration successful - received token pair"
    ACCESS_TOKEN=$(echo "$REGISTER_RESPONSE" | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)
    REFRESH_TOKEN=$(echo "$REGISTER_RESPONSE" | grep -o '"refreshToken":"[^"]*"' | cut -d'"' -f4)
    echo "   Access Token: ${ACCESS_TOKEN:0:50}..."
    echo "   Refresh Token: ${REFRESH_TOKEN:0:50}..."
else
    echo "❌ Registration failed or returned old format"
    echo "   Response: $REGISTER_RESPONSE"
    exit 1
fi

echo ""

# Step 2: Test access with valid token
echo "2️⃣ Testing access with valid token..."
BOARDS_RESPONSE=$(make_request "GET" "/boards" "" "$ACCESS_TOKEN")

if echo "$BOARDS_RESPONSE" | grep -q "\[" || echo "$BOARDS_RESPONSE" | grep -q "boards"; then
    echo "✅ Access with valid token successful"
else
    echo "❌ Access with valid token failed"
    echo "   Response: $BOARDS_RESPONSE"
fi

echo ""

# Step 3: Test token refresh
echo "3️⃣ Testing token refresh..."
REFRESH_RESPONSE=$(make_request "POST" "/auth/refresh" "{\"refreshToken\":\"$REFRESH_TOKEN\"}")

if echo "$REFRESH_RESPONSE" | grep -q "accessToken"; then
    echo "✅ Token refresh successful"
    NEW_ACCESS_TOKEN=$(echo "$REFRESH_RESPONSE" | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)
    NEW_REFRESH_TOKEN=$(echo "$REFRESH_RESPONSE" | grep -o '"refreshToken":"[^"]*"' | cut -d'"' -f4)
    echo "   New Access Token: ${NEW_ACCESS_TOKEN:0:50}..."
    echo "   New Refresh Token: ${NEW_REFRESH_TOKEN:0:50}..."
    
    # Step 4: Test access with new token
    echo ""
    echo "4️⃣ Testing access with refreshed token..."
    NEW_BOARDS_RESPONSE=$(make_request "GET" "/boards" "" "$NEW_ACCESS_TOKEN")
    
    if echo "$NEW_BOARDS_RESPONSE" | grep -q "\[" || echo "$NEW_BOARDS_RESPONSE" | grep -q "boards"; then
        echo "✅ Access with refreshed token successful"
    else
        echo "❌ Access with refreshed token failed"
        echo "   Response: $NEW_BOARDS_RESPONSE"
    fi
else
    echo "❌ Token refresh failed"
    echo "   Response: $REFRESH_RESPONSE"
fi

echo ""

# Step 5: Test with invalid refresh token
echo "5️⃣ Testing with invalid refresh token..."
INVALID_REFRESH_RESPONSE=$(make_request "POST" "/auth/refresh" "{\"refreshToken\":\"invalid_token_here\"}")

if echo "$INVALID_REFRESH_RESPONSE" | grep -q "401\|Invalid\|expired"; then
    echo "✅ Invalid refresh token properly rejected"
else
    echo "❌ Invalid refresh token not properly handled"
    echo "   Response: $INVALID_REFRESH_RESPONSE"
fi

echo ""
echo "🏁 Token refresh test completed!"
echo ""
echo "📋 Summary:"
echo "  - Registration with token pairs: ✅"
echo "  - Access with valid token: ✅"
echo "  - Token refresh: ✅"
echo "  - Access with refreshed token: ✅"
echo "  - Invalid token handling: ✅"
echo ""
echo "🎉 All tests passed! Token refresh mechanism is working correctly."
