#!/bin/bash

echo "🚀 Testing Complete Workflow: Boards, Cards, and State Changes"
echo "=============================================================="
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

echo "🔐 1. User Registration and Authentication"
echo "------------------------------------------"
# Register a new user
REGISTER_RESPONSE=$(curl -s -X POST "http://localhost:8080/auth/register" \
    -H "Content-Type: application/json" \
    -d '{"name":"Workflow Test User","email":"workflow2@example.com","password":"password123"}')

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

echo "📋 2. Creating Public Board"
echo "----------------------------"
test_endpoint_with_auth "POST" "/boards" '{"name":"Public Workflow Board 2","ownerId":"workflow-user-2","ownerName":"Workflow Test User 2","isPrivate":false}' "Create public board" "200" "$TOKEN"

# Extract board ID from response
BOARD_RESPONSE=$(curl -s -X POST "http://localhost:8080/boards" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{"name":"Public Workflow Board 2","ownerId":"workflow-user-2","ownerName":"Workflow Test User 2","isPrivate":false}')

PUBLIC_BOARD_ID=$(echo "$BOARD_RESPONSE" | grep -o '"id":[0-9]*' | cut -d':' -f2 | head -1)
echo "Public Board ID: $PUBLIC_BOARD_ID"
echo ""

echo "🔒 3. Creating Private Board"
echo "-----------------------------"
test_endpoint_with_auth "POST" "/boards" '{"name":"Private Workflow Board 2","ownerId":"workflow-user-2","ownerName":"Workflow Test User 2","isPrivate":true}' "Create private board" "200" "$TOKEN"

# Extract private board ID
PRIVATE_BOARD_RESPONSE=$(curl -s -X POST "http://localhost:8080/boards" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{"name":"Private Workflow Board 2","ownerId":"workflow-user-2","ownerName":"Workflow Test User 2","isPrivate":true}')

PRIVATE_BOARD_ID=$(echo "$PRIVATE_BOARD_RESPONSE" | grep -o '"id":[0-9]*' | cut -d':' -f2 | head -1)
echo "Private Board ID: $PRIVATE_BOARD_ID"
echo ""

echo "📋 4. Verifying Board Creation"
echo "-------------------------------"
test_endpoint_with_auth "GET" "/boards" "" "Get all boards to verify creation" "200" "$TOKEN"
test_endpoint_with_auth "GET" "/boards/$PUBLIC_BOARD_ID" "" "Get public board details" "200" "$TOKEN"
test_endpoint_with_auth "GET" "/boards/$PRIVATE_BOARD_ID" "" "Get private board details" "200" "$TOKEN"

echo "🃏 5. Creating Cards in Public Board"
echo "------------------------------------"
# First, get the lists to find the "To Do" list ID
LISTS_RESPONSE=$(curl -s -X GET "http://localhost:8080/lists" \
    -H "Authorization: Bearer $TOKEN")

echo "Available lists: $LISTS_RESPONSE"

# Find the "To Do" list for the public board
TODO_LIST_ID=$(echo "$LISTS_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
echo "Using To Do list ID: $TODO_LIST_ID"

# Create a card in the "To Do" list
test_endpoint_with_auth "POST" "/cards" "{\"title\":\"Test Card 1\",\"description\":\"This is a test card for workflow testing\",\"list\":{\"id\":$TODO_LIST_ID}}" "Create card in To Do list" "200" "$TOKEN"

# Create another card
test_endpoint_with_auth "POST" "/cards" "{\"title\":\"Test Card 2\",\"description\":\"Another test card for state changes\",\"list\":{\"id\":$TODO_LIST_ID}}" "Create second card in To Do list" "200" "$TOKEN"

echo "🔄 6. Testing Card State Changes"
echo "--------------------------------"
# Get all cards to see what we created
CARDS_RESPONSE=$(curl -s -X GET "http://localhost:8080/cards" \
    -H "Authorization: Bearer $TOKEN")

echo "All cards: $CARDS_RESPONSE"

# Extract the first card ID
FIRST_CARD_ID=$(echo "$CARDS_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
echo "First card ID: $FIRST_CARD_ID"

if [ -n "$FIRST_CARD_ID" ]; then
    echo "Testing card state changes..."
    
    # Test updating card metadata (title, description)
    test_endpoint_with_auth "PUT" "/cards/$FIRST_CARD_ID/update-metadata" "{\"title\":\"Updated Test Card\",\"label\":\"High Priority\"}" "Update card title and label" "200" "$TOKEN"
    
    # Test transitioning card state to "In Progress"
    test_endpoint_with_auth "PUT" "/cards/$FIRST_CARD_ID/transition?newState=In Progress" "" "Change card state to In Progress" "200" "$TOKEN"
    
    # Test transitioning card state to "Review"
    test_endpoint_with_auth "PUT" "/cards/$FIRST_CARD_ID/transition?newState=Review" "" "Change card state to Review" "200" "$TOKEN"
    
    # Test transitioning card state to "Done"
    test_endpoint_with_auth "PUT" "/cards/$FIRST_CARD_ID/transition?newState=Done" "" "Change card state to Done" "200" "$TOKEN"
    
    # Test viewing card history
    test_endpoint_with_auth "GET" "/cards/$FIRST_CARD_ID/history" "" "View card state history" "200" "$TOKEN"
else
    echo "❌ No card ID found, skipping state change tests"
    ((TESTS_FAILED+=5))
fi

echo "📊 7. Final Verification"
echo "------------------------"
test_endpoint_with_auth "GET" "/cards" "" "Get all cards to verify state changes" "200" "$TOKEN"
test_endpoint_with_auth "GET" "/boards/$PUBLIC_BOARD_ID" "" "Get public board with all lists and cards" "200" "$TOKEN"

echo ""
echo "📊 Workflow Test Results Summary"
echo "================================"
echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
echo "Total Tests: $((TESTS_PASSED + TESTS_FAILED))"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All workflow tests passed!${NC}"
    echo ""
    echo "📋 Summary of what was tested:"
    echo "✅ User registration and authentication"
    echo "✅ Public board creation"
    echo "✅ Private board creation"
    echo "✅ Card creation in 'To Do' list"
    echo "✅ Card metadata updates (title, label)"
    echo "✅ Card state transitions (To Do → In Progress → Review → Done)"
    echo "✅ Card history tracking"
    echo "✅ Board and list verification"
    exit 0
else
    echo -e "${RED}❌ Some workflow tests failed. Check the output above.${NC}"
    exit 1
fi
