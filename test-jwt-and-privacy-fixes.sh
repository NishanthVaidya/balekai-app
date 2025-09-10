#!/bin/bash

# Test JWT and Privacy Fixes Script
# This script tests the fixes for JWT validation and privacy filtering

set -e

# Configuration
BACKEND_URL="https://api.balekai.com"
# For local testing, use: BACKEND_URL="http://localhost:8080"

echo "🧪 Testing JWT and Privacy Fixes..."
echo "Backend URL: $BACKEND_URL"
echo ""

# Test 1: Register a test user
echo "1️⃣ Testing user registration..."
REGISTER_RESPONSE=$(curl -s -X POST "$BACKEND_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testuser@example.com",
    "password": "testpassword123",
    "name": "Test User"
  }')

echo "Register response: $REGISTER_RESPONSE"

# Extract token from response
TOKEN=$(echo $REGISTER_RESPONSE | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
    echo "❌ Failed to get JWT token from registration"
    exit 1
fi

echo "✅ JWT token obtained: ${TOKEN:0:20}..."
echo ""

# Test 2: Test JWT validation with POST request (board creation)
echo "2️⃣ Testing JWT validation with POST request (board creation)..."
CREATE_BOARD_RESPONSE=$(curl -s -X POST "$BACKEND_URL/boards" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "Test Board",
    "ownerName": "Test User",
    "isPrivate": true
  }')

echo "Create board response: $CREATE_BOARD_RESPONSE"

if echo "$CREATE_BOARD_RESPONSE" | grep -q '"id"'; then
    echo "✅ Board creation successful - JWT validation working!"
    BOARD_ID=$(echo $CREATE_BOARD_RESPONSE | grep -o '"id":[0-9]*' | cut -d':' -f2)
    echo "Board ID: $BOARD_ID"
else
    echo "❌ Board creation failed - JWT validation still broken"
    exit 1
fi
echo ""

# Test 3: Test privacy filtering (get user's boards)
echo "3️⃣ Testing privacy filtering (get user's boards)..."
GET_BOARDS_RESPONSE=$(curl -s -X GET "$BACKEND_URL/boards" \
  -H "Authorization: Bearer $TOKEN")

echo "Get boards response: $GET_BOARDS_RESPONSE"

if echo "$GET_BOARDS_RESPONSE" | grep -q '"name":"Test Board"'; then
    echo "✅ Privacy filtering working - user can see their own board"
else
    echo "❌ Privacy filtering not working - user cannot see their board"
    exit 1
fi
echo ""

# Test 4: Test unauthorized access (should fail)
echo "4️⃣ Testing unauthorized access (should fail)..."
UNAUTHORIZED_RESPONSE=$(curl -s -X GET "$BACKEND_URL/boards" \
  -H "Authorization: Bearer invalid_token")

echo "Unauthorized response: $UNAUTHORIZED_RESPONSE"

if echo "$UNAUTHORIZED_RESPONSE" | grep -q "Unauthorized"; then
    echo "✅ Unauthorized access properly blocked"
else
    echo "❌ Unauthorized access not properly blocked"
    exit 1
fi
echo ""

echo "🎉 All tests passed! The fixes are working correctly:"
echo "✅ JWT validation is working for POST requests"
echo "✅ Privacy filtering is working correctly"
echo "✅ Board creation is functional"
echo "✅ Unauthorized access is properly blocked"
