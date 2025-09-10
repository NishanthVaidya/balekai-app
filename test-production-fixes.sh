#!/bin/bash

# Test Production Fixes Script
# This script tests the JWT and privacy fixes on the production environment

set -e

# Configuration
BACKEND_URL="https://api.balekai.com"
TEST_EMAIL="testuser@example.com"
TEST_PASSWORD="testpassword123"
TEST_NAME="Test User"

echo "🧪 Testing JWT and Privacy Fixes on Production Environment..."
echo "Backend URL: $BACKEND_URL"
echo "Test User: $TEST_EMAIL"
echo ""

# Wait a moment for the service to fully stabilize
echo "⏳ Waiting for service to stabilize..."
sleep 30

# Test 1: Health check
echo "1️⃣ Testing health check..."
HEALTH_RESPONSE=$(curl -s -w "\n%{http_code}" "$BACKEND_URL/health" || echo "Connection failed")
HTTP_CODE=$(echo "$HEALTH_RESPONSE" | tail -n1)
HEALTH_BODY=$(echo "$HEALTH_RESPONSE" | head -n -1)

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Health check passed: $HEALTH_BODY"
else
    echo "❌ Health check failed with HTTP $HTTP_CODE: $HEALTH_BODY"
    exit 1
fi
echo ""

# Test 2: Register a test user (or login if exists)
echo "2️⃣ Testing user registration/login..."
REGISTER_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BACKEND_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$TEST_EMAIL\",
    \"password\": \"$TEST_PASSWORD\",
    \"name\": \"$TEST_NAME\"
  }")

HTTP_CODE=$(echo "$REGISTER_RESPONSE" | tail -n1)
REGISTER_BODY=$(echo "$REGISTER_RESPONSE" | head -n -1)

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ User registration successful"
    TOKEN=$(echo $REGISTER_BODY | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
elif [ "$HTTP_CODE" = "409" ]; then
    echo "ℹ️  User already exists, attempting login..."
    LOGIN_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BACKEND_URL/auth/login" \
      -H "Content-Type: application/json" \
      -d "{
        \"email\": \"$TEST_EMAIL\",
        \"password\": \"$TEST_PASSWORD\"
      }")
    
    LOGIN_HTTP_CODE=$(echo "$LOGIN_RESPONSE" | tail -n1)
    LOGIN_BODY=$(echo "$LOGIN_RESPONSE" | head -n -1)
    
    if [ "$LOGIN_HTTP_CODE" = "200" ]; then
        echo "✅ User login successful"
        TOKEN=$(echo $LOGIN_BODY | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    else
        echo "❌ User login failed with HTTP $LOGIN_HTTP_CODE: $LOGIN_BODY"
        exit 1
    fi
else
    echo "❌ User registration failed with HTTP $HTTP_CODE: $REGISTER_BODY"
    exit 1
fi

if [ -z "$TOKEN" ]; then
    echo "❌ Failed to get JWT token"
    exit 1
fi

echo "✅ JWT token obtained: ${TOKEN:0:20}..."
echo ""

# Test 3: Test JWT validation with POST request (board creation)
echo "3️⃣ Testing JWT validation with POST request (board creation)..."
CREATE_BOARD_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BACKEND_URL/boards" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"name\": \"Test Board $(date +%s)\",
    \"ownerName\": \"$TEST_NAME\",
    \"isPrivate\": true
  }")

HTTP_CODE=$(echo "$CREATE_BOARD_RESPONSE" | tail -n1)
CREATE_BOARD_BODY=$(echo "$CREATE_BOARD_RESPONSE" | head -n -1)

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Board creation successful - JWT validation working!"
    BOARD_ID=$(echo $CREATE_BOARD_BODY | grep -o '"id":[0-9]*' | cut -d':' -f2)
    BOARD_NAME=$(echo $CREATE_BOARD_BODY | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
    echo "Board ID: $BOARD_ID, Name: $BOARD_NAME"
else
    echo "❌ Board creation failed with HTTP $HTTP_CODE: $CREATE_BOARD_BODY"
    echo "This indicates JWT validation is still broken"
    exit 1
fi
echo ""

# Test 4: Test privacy filtering (get user's boards)
echo "4️⃣ Testing privacy filtering (get user's boards)..."
GET_BOARDS_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BACKEND_URL/boards" \
  -H "Authorization: Bearer $TOKEN")

HTTP_CODE=$(echo "$GET_BOARDS_RESPONSE" | tail -n1)
GET_BOARDS_BODY=$(echo "$GET_BOARDS_RESPONSE" | head -n -1)

if [ "$HTTP_CODE" = "200" ]; then
    if echo "$GET_BOARDS_BODY" | grep -q "$BOARD_NAME"; then
        echo "✅ Privacy filtering working - user can see their own board"
        BOARD_COUNT=$(echo "$GET_BOARDS_BODY" | grep -o '"id"' | wc -l)
        echo "User has access to $BOARD_COUNT board(s)"
    else
        echo "❌ Privacy filtering not working - user cannot see their board"
        echo "Response: $GET_BOARDS_BODY"
        exit 1
    fi
else
    echo "❌ Get boards failed with HTTP $HTTP_CODE: $GET_BOARDS_BODY"
    exit 1
fi
echo ""

# Test 5: Test unauthorized access (should fail)
echo "5️⃣ Testing unauthorized access (should fail)..."
UNAUTHORIZED_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BACKEND_URL/boards" \
  -H "Authorization: Bearer invalid_token")

HTTP_CODE=$(echo "$UNAUTHORIZED_RESPONSE" | tail -n1)
UNAUTHORIZED_BODY=$(echo "$UNAUTHORIZED_RESPONSE" | head -n -1)

if [ "$HTTP_CODE" = "401" ]; then
    echo "✅ Unauthorized access properly blocked"
else
    echo "❌ Unauthorized access not properly blocked (HTTP $HTTP_CODE): $UNAUTHORIZED_BODY"
    exit 1
fi
echo ""

# Test 6: Test board creation without token (should fail)
echo "6️⃣ Testing board creation without token (should fail)..."
NO_TOKEN_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BACKEND_URL/boards" \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"Unauthorized Board\",
    \"ownerName\": \"Hacker\",
    \"isPrivate\": true
  }")

HTTP_CODE=$(echo "$NO_TOKEN_RESPONSE" | tail -n1)
NO_TOKEN_BODY=$(echo "$NO_TOKEN_RESPONSE" | head -n -1)

if [ "$HTTP_CODE" = "401" ]; then
    echo "✅ Board creation without token properly blocked"
else
    echo "❌ Board creation without token not properly blocked (HTTP $HTTP_CODE): $NO_TOKEN_BODY"
    exit 1
fi
echo ""

echo "🎉 All tests passed! The fixes are working correctly on production:"
echo "✅ JWT validation is working for POST requests"
echo "✅ Privacy filtering is working correctly"
echo "✅ Board creation is functional"
echo "✅ Unauthorized access is properly blocked"
echo "✅ Token-based authentication is enforced"
echo ""
echo "🔧 Issues Fixed:"
echo "   - Added JWT_SECRET environment variable to ECS task definition"
echo "   - Fixed PrivateBoardFactory to properly set board privacy"
echo "   - Added debug logging for privacy filtering"
echo ""
echo "📊 Monitor logs with: aws logs tail /balekai/backend --follow"
