#!/bin/bash

echo "🚀 Final Comprehensive Endpoint Testing"
echo "======================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Function to test an endpoint
test_endpoint() {
    local method=$1
    local endpoint=$2
    local data=$3
    local description=$4
    local expected_status=$5
    
    echo -e "${BLUE}Testing: ${description}${NC}"
    echo "Endpoint: $method $endpoint"
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "\n%{http_code}" -X GET "http://localhost:8080$endpoint")
    elif [ "$method" = "POST" ]; then
        response=$(curl -s -w "\n%{http_code}" -X POST "http://localhost:8080$endpoint" \
            -H "Content-Type: application/json" \
            -d "$data")
    elif [ "$method" = "PUT" ]; then
        response=$(curl -s -w "\n%{http_code}" -X PUT "http://localhost:8080$endpoint" \
            -H "Content-Type: application/json" \
            -d "$data")
    elif [ "$method" = "DELETE" ]; then
        response=$(curl -s -w "\n%{http_code}" -X DELETE "http://localhost:8080$endpoint")
    fi
    
    # Extract response body and status code
    body=$(echo "$response" | sed '$d')
    status=$(echo "$response" | tail -n 1)
    
    echo "Status: $status"
    echo "Response: $body"
    
    if [ "$status" = "$expected_status" ]; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ FAIL - Expected $expected_status, got $status${NC}"
        ((TESTS_FAILED++))
    fi
    echo ""
}

# Function to test with authentication
test_endpoint_with_auth() {
    local method=$1
    local endpoint=$2
    local data=$3
    local description=$4
    local expected_status=$5
    local token=$6
    
    echo -e "${BLUE}Testing: ${description}${NC}"
    echo "Endpoint: $method $endpoint"
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "\n%{http_code}" -X GET "http://localhost:8080$endpoint" \
            -H "Authorization: Bearer $token")
    elif [ "$method" = "POST" ]; then
        response=$(curl -s -w "\n%{http_code}" -X POST "http://localhost:8080$endpoint" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $token" \
            -d "$data")
    elif [ "$method" = "PUT" ]; then
        response=$(curl -s -w "\n%{http_code}" -X PUT "http://localhost:8080$endpoint" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $token" \
            -d "$data")
    elif [ "$method" = "DELETE" ]; then
        response=$(curl -s -w "\n%{http_code}" -X DELETE "http://localhost:8080$endpoint" \
            -H "Authorization: Bearer $token")
    fi
    
    # Extract response body and status code
    body=$(echo "$response" | sed '$d')
    status=$(echo "$response" | tail -n 1)
    
    echo "Status: $status"
    echo "Response: $body"
    
    if [ "$status" = "$expected_status" ]; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ FAIL - Expected $expected_status, got $status${NC}"
        ((TESTS_FAILED++))
    fi
    echo ""
}

echo "📋 1. Testing Public Endpoints (No Auth Required)"
echo "-------------------------------------------------"
test_endpoint "GET" "/" "" "Root endpoint" "200"
test_endpoint "GET" "/health" "" "Health check endpoint" "200"
test_endpoint "GET" "/users" "" "Users endpoint" "200"

echo "🔐 2. Testing Authentication Endpoints (No Auth Required)"
echo "--------------------------------------------------------"
test_endpoint "GET" "/auth/test" "" "Firebase test endpoint" "500"
test_endpoint "POST" "/auth/register" '{"name":"Final Test User","email":"finaltest@example.com","password":"password123"}' "User registration" "200"
test_endpoint "POST" "/auth/login" '{"name":"Final Test User","email":"finaltest@example.com","password":"password123"}' "User login" "200"

echo "📋 3. Testing Protected Endpoints (Without Auth - Should Fail)"
echo "---------------------------------------------------------------"
test_endpoint "GET" "/boards" "" "Get all boards without auth" "401"
test_endpoint "POST" "/boards" '{"name":"Test Board","ownerId":"test-user","ownerName":"Test User","isPrivate":false}' "Create board without auth" "401"
test_endpoint "GET" "/lists" "" "Get all lists without auth" "401"
test_endpoint "POST" "/lists" '{"name":"Test List"}' "Create list without auth" "401"
test_endpoint "GET" "/cards" "" "Get all cards without auth" "401"
test_endpoint "POST" "/cards" '{"title":"Test Card","description":"Test Description"}' "Create card without auth" "401"

echo "🔑 4. Testing Protected Endpoints (With Valid Auth)"
echo "---------------------------------------------------"
# Get the token from registration
REGISTER_RESPONSE=$(curl -s -X POST "http://localhost:8080/auth/register" \
    -H "Content-Type: application/json" \
    -d '{"name":"Auth Final User","email":"authfinal@example.com","password":"password123"}')

echo "Registration response: $REGISTER_RESPONSE"
TOKEN="$REGISTER_RESPONSE"

if [ -n "$TOKEN" ] && [ "$TOKEN" != "Email already in use" ]; then
    echo "Using token: $TOKEN"
    
    test_endpoint_with_auth "GET" "/boards" "" "Get all boards with auth" "200" "$TOKEN"
    test_endpoint_with_auth "POST" "/boards" '{"name":"Final Test Board","ownerId":"final-test-user","ownerName":"Final Test User","isPrivate":false}' "Create board with auth" "200" "$TOKEN"
    test_endpoint_with_auth "GET" "/lists" "" "Get all lists with auth" "200" "$TOKEN"
    test_endpoint_with_auth "POST" "/lists" '{"name":"Final Test List"}' "Create list with auth" "200" "$TOKEN"
    test_endpoint_with_auth "GET" "/cards" "" "Get all cards with auth" "200" "$TOKEN"
else
    echo "Failed to get valid token, skipping authenticated tests"
    ((TESTS_FAILED+=6))
fi

echo "🔒 5. Testing Protected Endpoints (With Invalid Auth)"
echo "----------------------------------------------------"
test_endpoint_with_auth "GET" "/boards" "" "Get boards with invalid token" "401" "invalid-token"
test_endpoint_with_auth "POST" "/boards" '{"name":"Test Board"}' "Create board with invalid token" "401" "invalid-token"

echo "🔄 6. Testing CRUD Operations (With Valid Auth)"
echo "------------------------------------------------"
if [ -n "$TOKEN" ] && [ "$TOKEN" != "Email already in use" ]; then
    echo "Testing CRUD operations with token: $TOKEN"
    
    # Test board creation
    BOARD_RESPONSE=$(curl -s -X POST "http://localhost:8080/boards" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $TOKEN" \
        -d '{"name":"CRUD Test Board","ownerId":"crud-test-user","ownerName":"CRUD Test User","isPrivate":false}')
    
    echo "Board created: $BOARD_RESPONSE"
    
    # Extract board ID for further testing
    BOARD_ID=$(echo "$BOARD_RESPONSE" | grep -o '"id":[0-9]*' | cut -d':' -f2 | head -1)
    
    if [ -n "$BOARD_ID" ]; then
        echo "Testing with board ID: $BOARD_ID"
        
        # Test getting specific board
        test_endpoint_with_auth "GET" "/boards/$BOARD_ID" "" "Get specific board" "200" "$TOKEN"
        
        # Test updating board
        test_endpoint_with_auth "PUT" "/boards/$BOARD_ID" '{"name":"Updated CRUD Board","ownerId":"crud-test-user","ownerName":"CRUD Test User","isPrivate":false}' "Update board" "200" "$TOKEN"
        
        # Test deleting board
        test_endpoint_with_auth "DELETE" "/boards/$BOARD_ID" "" "Delete board" "200" "$TOKEN"
    else
        echo "Failed to get board ID, skipping CRUD tests"
        ((TESTS_FAILED+=3))
    fi
else
    echo "No valid token available, skipping CRUD tests"
    ((TESTS_FAILED+=3))
fi

echo ""
echo "📊 Final Test Results Summary"
echo "============================="
echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
echo "Total Tests: $((TESTS_PASSED + TESTS_FAILED))"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed! Your API is fully functional!${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠️  Some tests failed. Check the output above for details.${NC}"
    exit 1
fi
