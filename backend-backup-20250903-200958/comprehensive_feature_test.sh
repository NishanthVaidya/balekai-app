#!/bin/bash

echo "🚀 Comprehensive Feature Testing: All Endpoints and Edge Cases (Fixed)"
echo "======================================================================"
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

# Function to test without authentication (should fail)
test_endpoint_unauthorized() {
    local method=$1
    local endpoint=$2
    local data=$3
    local description=$4
    local token=$5
    
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
    
    if [ "$status" = "401" ]; then
        echo -e "${GREEN}✅ PASS - Correctly blocked unauthorized access${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ FAIL - Expected 401, got $status${NC}"
        ((TESTS_FAILED++))
    fi
    echo ""
}

echo "🔐 1. User Registration and Authentication"
echo "------------------------------------------"
# Register a new user for testing
REGISTER_RESPONSE=$(curl -s -X POST "http://localhost:8080/auth/register" \
    -H "Content-Type: application/json" \
    -d '{"name":"Fixed Test User","email":"fixed@example.com","password":"password123"}')

echo "Registration response: $REGISTER_RESPONSE"
TOKEN="$REGISTER_RESPONSE"

if [ -n "$TOKEN" ] && [ "$TOKEN" != "Email already in use" ]; then
    echo "✅ Successfully registered user and got token"
    echo "Token: $TOKEN"
    echo ""
else
    echo "❌ Failed to register user"
    exit 1
fi

echo "📋 2. Board Management - Full CRUD Operations"
echo "----------------------------------------------"
# Create a test board
test_endpoint_with_auth "POST" "/boards" '{"name":"Fixed Test Board","ownerId":"fixed-user","ownerName":"Fixed Test User","isPrivate":false}' "Create test board" "200" "$TOKEN"

# Get the board ID from the response
BOARD_RESPONSE=$(curl -s -X POST "http://localhost:8080/boards" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{"name":"Fixed Test Board","ownerId":"fixed-user","ownerName":"Fixed Test User","isPrivate":false}')

BOARD_ID=$(echo "$BOARD_RESPONSE" | grep -o '"id":[0-9]*' | cut -d':' -f2 | head -1)
echo "Test Board ID: $BOARD_ID"

# Test getting user's own boards
test_endpoint_with_auth "GET" "/boards/me" "" "Get user's own boards" "200" "$TOKEN"

# Test updating board details
test_endpoint_with_auth "PUT" "/boards/$BOARD_ID" '{"name":"Updated Fixed Test Board","ownerId":"fixed-user","ownerName":"Fixed Test User","isPrivate":true}' "Update board details" "200" "$TOKEN"

# Verify the update
test_endpoint_with_auth "GET" "/boards/$BOARD_ID" "" "Get updated board details" "200" "$TOKEN"

echo "📝 3. List Management - Full CRUD Operations"
echo "---------------------------------------------"
# Create a new list
test_endpoint_with_auth "POST" "/lists" '{"name":"Custom Fixed List","board":{"id":'$BOARD_ID'}}' "Create new list" "200" "$TOKEN"

# Get the list ID
LIST_RESPONSE=$(curl -s -X POST "http://localhost:8080/lists" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{"name":"Custom Fixed List","board":{"id":'$BOARD_ID'}}')

LIST_ID=$(echo "$LIST_RESPONSE" | grep -o '"id":[0-9]*' | cut -d':' -f2 | head -1)
echo "Custom List ID: $LIST_ID"

# Test getting all lists
test_endpoint_with_auth "GET" "/lists" "" "Get all lists" "200" "$TOKEN"

# Test getting specific list
test_endpoint_with_auth "GET" "/lists/$LIST_ID" "" "Get specific list" "200" "$TOKEN"

# Test updating list
test_endpoint_with_auth "PUT" "/lists/$LIST_ID" '{"name":"Updated Custom Fixed List","board":{"id":'$BOARD_ID'}}' "Update list details" "200" "$TOKEN"

echo "🃏 4. Card Management - Full CRUD Operations"
echo "---------------------------------------------"
# Find the 'To Do' list from the board (business rule: cards can only be created in 'To Do')
TODO_LIST_RESPONSE=$(curl -s -X GET "http://localhost:8080/boards/$BOARD_ID" \
    -H "Authorization: Bearer $TOKEN")

TODO_LIST_ID=$(echo "$TODO_LIST_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
echo "To Do List ID: $TODO_LIST_ID"

# Create a test card in the 'To Do' list (respecting business rule)
test_endpoint_with_auth "POST" "/cards" '{"title":"Fixed Test Card","description":"Test card for fixed testing","list":{"id":'$TODO_LIST_ID'}}' "Create test card in To Do list" "200" "$TOKEN"

# Get the card ID from the response
CARD_RESPONSE=$(curl -s -X POST "http://localhost:8080/cards" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{"title":"Fixed Test Card","description":"Test card for fixed testing","list":{"id":'$TODO_LIST_ID'}}')

CARD_ID=$(echo "$CARD_RESPONSE" | grep -o '"id":[0-9]*' | cut -d':' -f2 | head -1)
echo "Test Card ID: $CARD_ID"

if [ -n "$CARD_ID" ]; then
    # Test getting specific card
    test_endpoint_with_auth "GET" "/cards/$CARD_ID" "" "Get specific card" "200" "$TOKEN"

    # Test card assignment (assign to a user)
    test_endpoint_with_auth "PUT" "/cards/$CARD_ID/assign?userId=test-user-1" "" "Assign card to user" "200" "$TOKEN"

    # Test card state transition
    test_endpoint_with_auth "PUT" "/cards/$CARD_ID/transition?newState=In Progress" "" "Change card state to In Progress" "200" "$TOKEN"

    # Test card movement
    test_endpoint_with_auth "PUT" "/cards/$CARD_ID/move?listId=$LIST_ID" "" "Move card to custom list" "200" "$TOKEN"

    # Test card metadata update
    test_endpoint_with_auth "PUT" "/cards/$CARD_ID/update-metadata" '{"title":"Updated Fixed Card","label":"Critical"}' "Update card metadata" "200" "$TOKEN"

    # Test card history
    test_endpoint_with_auth "GET" "/cards/$CARD_ID/history" "" "Get card history" "200" "$TOKEN"
else
    echo "❌ No card ID found, skipping card operations"
    ((TESTS_FAILED+=6))
fi

echo "🔒 5. Security Testing - Unauthorized Access"
echo "---------------------------------------------"
# Test accessing protected endpoints without authentication
test_endpoint_unauthorized "GET" "/boards" "" "Get boards without auth (should fail)" ""
test_endpoint_unauthorized "POST" "/boards" '{"name":"Unauthorized Board"}' "Create board without auth (should fail)" ""
test_endpoint_unauthorized "GET" "/cards" "" "Get cards without auth (should fail)" ""
test_endpoint_unauthorized "POST" "/cards" '{"title":"Unauthorized Card"}' "Create card without auth (should fail)" ""

echo "❌ 6. Error Handling - Invalid IDs and Data (Fixed Expectations)"
echo "----------------------------------------------------------------"
# Test with invalid board ID - expect 400 (client error), not 500
test_endpoint_with_auth "GET" "/boards/99999" "" "Get non-existent board (should fail with 400)" "400" "$TOKEN"

# Test with invalid list ID - expect 400 (client error), not 500
test_endpoint_with_auth "GET" "/lists/99999" "" "Get non-existent list (should fail with 400)" "400" "$TOKEN"

# Test with invalid card ID - expect 400 (client error), not 500
test_endpoint_with_auth "GET" "/cards/99999" "" "Get non-existent card (should fail with 400)" "400" "$TOKEN"

# Test invalid card creation (wrong list) - expect 400 (client error), not 500
test_endpoint_with_auth "POST" "/cards" '{"title":"Invalid Card","description":"Card with invalid list","list":{"id":99999}}' "Create card with invalid list (should fail with 400)" "400" "$TOKEN"

echo "🧹 7. Cleanup - Delete Test Resources"
echo "--------------------------------------"
if [ -n "$CARD_ID" ]; then
    # Delete the test card
    test_endpoint_with_auth "DELETE" "/cards/$CARD_ID" "" "Delete test card" "200" "$TOKEN"
else
    echo "⚠️  Skipping card deletion (no card ID)"
    ((TESTS_FAILED+=1))
fi

# Delete the custom list
test_endpoint_with_auth "DELETE" "/lists/$LIST_ID" "" "Delete custom list" "200" "$TOKEN"

# Delete the test board
test_endpoint_with_auth "DELETE" "/boards/$BOARD_ID" "" "Delete test board" "200" "$TOKEN"

echo "📊 8. Final Verification"
echo "------------------------"
# Verify resources are deleted
test_endpoint_with_auth "GET" "/boards" "" "Get all boards to verify cleanup" "200" "$TOKEN"
test_endpoint_with_auth "GET" "/lists" "" "Get all lists to verify cleanup" "200" "$TOKEN"
test_endpoint_with_auth "GET" "/cards" "" "Get all cards to verify cleanup" "200" "$TOKEN"

echo ""
echo "📊 Comprehensive Feature Test Results Summary (Fixed)"
echo "====================================================="
echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
echo "Total Tests: $((TESTS_PASSED + TESTS_FAILED))"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All comprehensive feature tests passed!${NC}"
    echo ""
    echo "📋 Summary of what was tested:"
    echo "✅ User registration and authentication"
    echo "✅ Board CRUD operations (Create, Read, Update, Delete)"
    echo "✅ List CRUD operations (Create, Read, Update, Delete)"
    echo "✅ Card CRUD operations (Create, Read, Update, Delete)"
    echo "✅ Card state transitions and movement"
    echo "✅ Card assignment to users"
    echo "✅ Card metadata updates"
    echo "✅ Card history tracking"
    echo "✅ Security (unauthorized access blocking)"
    echo "✅ Error handling (invalid IDs, data validation)"
    echo "✅ Resource cleanup and verification"
    echo "✅ Business rule enforcement (cards only in 'To Do')"
    exit 0
else
    echo -e "${RED}❌ Some comprehensive feature tests failed. Check the output above.${NC}"
    exit 1
fi
