#!/bin/bash

echo "🧪 Testing Live AWS Backend - All Core Endpoints"
echo "================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BASE_URL="http://balekai-alb-new-626347040.us-east-1.elb.amazonaws.com"
REGISTER_EMAIL="test-aws-$(date +%s)@example.com"
REGISTER_PASSWORD="password123"
REGISTER_NAME="AWS Test User"

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Function to test endpoint
test_endpoint() {
    local method=$1
    local endpoint=$2
    local data=$3
    local description=$4
    local expected_status=$5
    local auth_token=$6
    
    echo -e "${BLUE}Testing: ${description}${NC}"
    echo "Endpoint: $method $endpoint"
    
    if [ "$method" = "GET" ]; then
        if [ -n "$auth_token" ]; then
            response=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL$endpoint" \
                -H "Authorization: Bearer $auth_token")
        else
            response=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL$endpoint")
        fi
    elif [ "$method" = "POST" ]; then
        if [ -n "$auth_token" ]; then
            response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL$endpoint" \
                -H "Content-Type: application/json" \
                -H "Authorization: Bearer $auth_token" \
                -d "$data")
        else
            response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL$endpoint" \
                -H "Content-Type: application/json" \
                -d "$data")
        fi
    elif [ "$method" = "PUT" ]; then
        response=$(curl -s -w "\n%{http_code}" -X PUT "$BASE_URL$endpoint" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $auth_token" \
            -d "$data")
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

echo "🔐 1. Authentication Testing"
echo "----------------------------"

# Test registration
echo "Testing user registration..."
REGISTER_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"$REGISTER_NAME\",\"email\":\"$REGISTER_EMAIL\",\"password\":\"$REGISTER_PASSWORD\"}")

if [[ "$REGISTER_RESPONSE" == *"eyJ"* ]]; then
    echo -e "${GREEN}✅ Registration successful - JWT token received${NC}"
    AUTH_TOKEN="$REGISTER_RESPONSE"
    echo "Token: ${AUTH_TOKEN:0:50}..."
else
    echo -e "${RED}❌ Registration failed${NC}"
    echo "Response: $REGISTER_RESPONSE"
    exit 1
fi

echo ""

# Test login
echo "Testing user login..."
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"$REGISTER_NAME\",\"email\":\"$REGISTER_EMAIL\",\"password\":\"$REGISTER_PASSWORD\"}")

if [[ "$LOGIN_RESPONSE" == *"eyJ"* ]]; then
    echo -e "${GREEN}✅ Login successful - JWT token received${NC}"
    AUTH_TOKEN="$LOGIN_RESPONSE"
    echo "Token: ${AUTH_TOKEN:0:50}..."
else
    echo -e "${RED}❌ Login failed${NC}"
    echo "Response: $LOGIN_RESPONSE"
fi

echo ""

echo "📋 2. Board Management Testing"
echo "------------------------------"

# Test board creation
test_endpoint "POST" "/boards" "{\"name\":\"AWS Test Board\",\"ownerId\":\"aws-test-user\",\"ownerName\":\"$REGISTER_NAME\",\"isPrivate\":false}" "Create test board" "200" "$AUTH_TOKEN"

# Get the board ID from the response
BOARD_RESPONSE=$(curl -s -X POST "$BASE_URL/boards" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $AUTH_TOKEN" \
    -d "{\"name\":\"AWS Test Board\",\"ownerId\":\"aws-test-user\",\"ownerName\":\"$REGISTER_NAME\",\"isPrivate\":false}")

BOARD_ID=$(echo "$BOARD_RESPONSE" | grep -o '"id":[0-9]*' | cut -d':' -f2 | head -1)
echo "Test Board ID: $BOARD_ID"

# Test getting user's own boards
test_endpoint "GET" "/boards/me" "" "Get user's own boards" "200" "$AUTH_TOKEN"

# Test getting specific board
if [ -n "$BOARD_ID" ]; then
    test_endpoint "GET" "/boards/$BOARD_ID" "" "Get specific board" "200" "$AUTH_TOKEN"
    
    # Test updating board
    test_endpoint "PUT" "/boards/$BOARD_ID" "{\"name\":\"Updated AWS Test Board\",\"ownerId\":\"aws-test-user\",\"ownerName\":\"$REGISTER_NAME\",\"isPrivate\":true}" "Update board details" "200" "$AUTH_TOKEN"
else
    echo -e "${RED}❌ No board ID found, skipping board operations${NC}"
    ((TESTS_FAILED+=3))
fi

echo "📝 3. List Management Testing"
echo "-----------------------------"

# Test getting all lists
test_endpoint "GET" "/lists" "" "Get all lists" "200" "$AUTH_TOKEN"

# Test creating a new list
test_endpoint "POST" "/lists" "{\"name\":\"AWS Test List\",\"board\":{\"id\":$BOARD_ID}}" "Create new list" "200" "$AUTH_TOKEN"

# Get the list ID
LIST_RESPONSE=$(curl -s -X POST "$BASE_URL/lists" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $AUTH_TOKEN" \
    -d "{\"name\":\"AWS Test List\",\"board\":{\"id\":$BOARD_ID}}")

LIST_ID=$(echo "$LIST_RESPONSE" | grep -o '"id":[0-9]*' | cut -d':' -f2 | head -1)
echo "Test List ID: $LIST_ID"

if [ -n "$LIST_ID" ]; then
    # Test getting specific list
    test_endpoint "GET" "/lists/$LIST_ID" "" "Get specific list" "200" "$AUTH_TOKEN"
    
    # Test updating list
    test_endpoint "PUT" "/lists/$LIST_ID" "{\"name\":\"Updated AWS Test List\",\"board\":{\"id\":$BOARD_ID}}" "Update list details" "200" "$AUTH_TOKEN"
else
    echo -e "${RED}❌ No list ID found, skipping list operations${NC}"
    ((TESTS_FAILED+=2))
fi

echo "🃏 4. Card Management Testing"
echo "-----------------------------"

# Find the 'To Do' list from the board (business rule: cards can only be created in 'To Do')
TODO_LIST_RESPONSE=$(curl -s -X GET "$BASE_URL/boards/$BOARD_ID" \
    -H "Authorization: Bearer $AUTH_TOKEN")

TODO_LIST_ID=$(echo "$TODO_LIST_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
echo "To Do List ID: $TODO_LIST_ID"

if [ -n "$TODO_LIST_ID" ]; then
    # Test card creation
    test_endpoint "POST" "/cards" "{\"title\":\"AWS Test Card\",\"description\":\"Test card for AWS deployment\",\"list\":{\"id\":$TODO_LIST_ID}}" "Create test card" "200" "$AUTH_TOKEN"
    
    # Get the card ID
    CARD_RESPONSE=$(curl -s -X POST "$BASE_URL/cards" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $AUTH_TOKEN" \
        -d "{\"title\":\"AWS Test Card\",\"description\":\"Test card for AWS deployment\",\"list\":{\"id\":$TODO_LIST_ID}}")
    
    CARD_ID=$(echo "$CARD_RESPONSE" | grep -o '"id":[0-9]*' | cut -d':' -f2 | head -1)
    echo "Test Card ID: $CARD_ID"
    
    if [ -n "$CARD_ID" ]; then
        # Test getting specific card
        test_endpoint "GET" "/cards/$CARD_ID" "" "Get specific card" "200" "$AUTH_TOKEN"
        
        # Test card assignment
        test_endpoint "PUT" "/cards/$CARD_ID/assign?userId=aws-test-user" "" "Assign card to user" "200" "$AUTH_TOKEN"
        
        # Test card state transition
        test_endpoint "PUT" "/cards/$CARD_ID/transition?newState=In Progress" "" "Change card state to In Progress" "200" "$AUTH_TOKEN"
        
        # Test card metadata update
        test_endpoint "PUT" "/cards/$CARD_ID/update-metadata" "{\"title\":\"Updated AWS Test Card\",\"label\":\"Critical\"}" "Update card metadata" "200" "$AUTH_TOKEN"
        
        # Test card history
        test_endpoint "GET" "/cards/$CARD_ID/history" "" "Get card history" "200" "$AUTH_TOKEN"
        
        # Test card movement
        if [ -n "$LIST_ID" ]; then
            test_endpoint "PUT" "/cards/$CARD_ID/move?listId=$LIST_ID" "" "Move card to custom list" "200" "$AUTH_TOKEN"
        fi
    else
        echo -e "${RED}❌ No card ID found, skipping card operations${NC}"
        ((TESTS_FAILED+=6))
    fi
else
    echo -e "${RED}❌ No To Do list found, skipping card operations${NC}"
    ((TESTS_FAILED+=7))
fi

echo "👥 5. User Management Testing"
echo "-----------------------------"

# Test getting all users
test_endpoint "GET" "/users" "" "Get all users" "200" "$AUTH_TOKEN"

echo "🔒 6. Security Testing"
echo "----------------------"

# Test accessing protected endpoints without authentication
echo "Testing unauthorized access to protected endpoints..."

# Test boards without auth
UNAUTH_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/boards")
UNAUTH_STATUS=$(echo "$UNAUTH_RESPONSE" | tail -n 1)

if [ "$UNAUTH_STATUS" = "401" ]; then
    echo -e "${GREEN}✅ PASS - Unauthorized access correctly blocked for /boards${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}❌ FAIL - Expected 401 for unauthorized /boards, got $UNAUTH_STATUS${NC}"
    ((TESTS_FAILED++))
fi

# Test cards without auth
UNAUTH_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/cards")
UNAUTH_STATUS=$(echo "$UNAUTH_RESPONSE" | tail -n 1)

if [ "$UNAUTH_STATUS" = "401" ]; then
    echo -e "${GREEN}✅ PASS - Unauthorized access correctly blocked for /cards${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}❌ FAIL - Expected 401 for unauthorized /cards, got $UNAUTH_STATUS${NC}"
    ((TESTS_FAILED++))
fi

echo ""

echo "❌ 7. Error Handling Testing"
echo "----------------------------"

# Test with invalid IDs
test_endpoint "GET" "/boards/99999" "" "Get non-existent board (should fail with 400)" "400" "$AUTH_TOKEN"
test_endpoint "GET" "/lists/99999" "" "Get non-existent list (should fail with 400)" "400" "$AUTH_TOKEN"
test_endpoint "GET" "/cards/99999" "" "Get non-existent card (should fail with 400)" "400" "$AUTH_TOKEN"

echo "🧹 8. Cleanup Testing"
echo "----------------------"

# Clean up test resources
if [ -n "$CARD_ID" ]; then
    test_endpoint "DELETE" "/cards/$CARD_ID" "" "Delete test card" "200" "$AUTH_TOKEN"
fi

if [ -n "$LIST_ID" ]; then
    test_endpoint "DELETE" "/lists/$LIST_ID" "" "Delete test list" "200" "$AUTH_TOKEN"
fi

if [ -n "$BOARD_ID" ]; then
    test_endpoint "DELETE" "/boards/$BOARD_ID" "" "Delete test board" "200" "$AUTH_TOKEN"
fi

echo ""
echo "📊 AWS Backend Test Results Summary"
echo "==================================="
echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
echo "Total Tests: $((TESTS_PASSED + TESTS_FAILED))"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All AWS backend tests passed! Your fixes are working in production!${NC}"
    echo ""
    echo "📋 Summary of what was tested:"
    echo "✅ Authentication (registration, login, JWT)"
    echo "✅ Board CRUD operations"
    echo "✅ List CRUD operations"
    echo "✅ Card CRUD operations"
    echo "✅ Card state transitions and movement"
    echo "✅ Card assignment to users"
    echo "✅ Card metadata updates"
    echo "✅ Card history tracking"
    echo "✅ User management"
    echo "✅ Security (unauthorized access blocking)"
    echo "✅ Error handling (invalid IDs)"
    echo "✅ Resource cleanup"
    echo ""
    echo "🚀 Ready to proceed to Step 2: Frontend Integration!"
    exit 0
else
    echo -e "${RED}❌ Some AWS backend tests failed. Check the output above.${NC}"
    exit 1
fi
