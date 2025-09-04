#!/bin/bash

echo "🚀 Starting Comprehensive Endpoint Testing"
echo "=========================================="
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

echo "📋 1. Testing Basic Health and Root Endpoints"
echo "---------------------------------------------"
test_endpoint "GET" "/" "" "Root endpoint" "200"
test_endpoint "GET" "/health" "" "Health check endpoint" "200"

echo "🔐 2. Testing Authentication Endpoints"
echo "--------------------------------------"
test_endpoint "GET" "/auth/test" "" "Firebase test endpoint" "200"
test_endpoint "POST" "/auth/register" '{"name":"Test User","email":"test@example.com","password":"password123"}' "User registration" "200"
test_endpoint "POST" "/auth/login" '{"name":"Test User","email":"test@example.com","password":"password123"}' "User login" "200"

echo "📋 3. Testing Board Endpoints (Without Auth - Should Fail)"
echo "-----------------------------------------------------------"
test_endpoint "GET" "/boards" "" "Get all boards without auth" "401"
test_endpoint "POST" "/boards" '{"name":"Test Board","ownerId":"test-user","ownerName":"Test User","isPrivate":false}' "Create board without auth" "401"

echo "📋 4. Testing List Endpoints (Without Auth - Should Fail)"
echo "----------------------------------------------------------"
test_endpoint "GET" "/lists" "" "Get all lists without auth" "401"
test_endpoint "POST" "/lists" '{"name":"Test List"}' "Create list without auth" "401"

echo "🃏 5. Testing Card Endpoints (Without Auth - Should Fail)"
echo "----------------------------------------------------------"
test_endpoint "GET" "/cards" "" "Get all cards without auth" "401"
test_endpoint "POST" "/cards" '{"title":"Test Card","description":"Test Description"}' "Create card without auth" "401"

echo "👥 6. Testing User Endpoints"
echo "-----------------------------"
test_endpoint "GET" "/users" "" "Get users endpoint" "200"

echo ""
echo "📊 Test Results Summary"
echo "======================="
echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
echo "Total Tests: $((TESTS_PASSED + TESTS_FAILED))"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Check the output above.${NC}"
    exit 1
fi
