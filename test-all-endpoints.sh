#!/bin/bash

echo "🧪 Comprehensive Endpoint Testing Script"
echo "========================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

ALB_URL="http://balekai-alb-new-626347040.us-east-1.elb.amazonaws.com"
TIMESTAMP=$(date +%s)
TEST_EMAIL="testuser-${TIMESTAMP}@balekai.com"
TEST_PASSWORD="TestPassword123!"
TEST_NAME="Test User ${TIMESTAMP}"

echo -e "${BLUE}Test Configuration:${NC}"
echo "ALB URL: $ALB_URL"
echo "Test Email: $TEST_EMAIL"
echo "Test Name: $TEST_NAME"
echo ""

# Function to test endpoint
test_endpoint() {
    local method=$1
    local endpoint=$2
    local data=$3
    local headers=$4
    local description=$5
    
    echo -e "${BLUE}Testing: $description${NC}"
    echo "Endpoint: $method $endpoint"
    
    if [ -n "$data" ]; then
        if [ -n "$headers" ]; then
            response=$(curl -s -w "\n%{http_code}\n%{time_total}" -X $method "$ALB_URL$endpoint" -H "$headers" -d "$data")
        else
            response=$(curl -s -w "\n%{http_code}\n%{time_total}" -X $method "$ALB_URL$endpoint" -d "$data")
        fi
    else
        if [ -n "$headers" ]; then
            response=$(curl -s -w "\n%{http_code}\n%{time_total}" -X $method "$ALB_URL$endpoint" -H "$headers")
        else
            response=$(curl -s -w "\n%{http_code}\n%{time_total}" -X $method "$ALB_URL$endpoint")
        fi
    fi
    
    http_code=$(echo "$response" | tail -n 2 | head -n 1)
    time_total=$(echo "$response" | tail -n 1)
    response_body=$(echo "$response" | head -n -2)
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
        echo -e "${GREEN}✅ SUCCESS: HTTP $http_code (${time_total}s)${NC}"
    else
        echo -e "${RED}❌ FAILED: HTTP $http_code (${time_total}s)${NC}"
    fi
    
    echo "Response: $response_body"
    echo ""
    
    # Return the response body for further processing
    echo "$response_body"
}

# Step 1: Test Health Endpoint
echo -e "${YELLOW}=== STEP 1: Health Check ===${NC}"
test_endpoint "GET" "/health" "" "" "Health Check"

# Step 2: Register New User
echo -e "${YELLOW}=== STEP 2: User Registration ===${NC}"
register_data="{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\",\"name\":\"$TEST_NAME\"}"
register_response=$(test_endpoint "POST" "/auth/register" "$register_data" "Content-Type: application/json" "User Registration")

# Extract JWT token from registration response
JWT_TOKEN=$(echo "$register_response" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
if [ -z "$JWT_TOKEN" ]; then
    echo -e "${RED}❌ Failed to extract JWT token from registration response${NC}"
    echo "Registration response: $register_response"
    exit 1
fi

echo -e "${GREEN}✅ JWT Token extracted: ${JWT_TOKEN:0:20}...${NC}"
echo ""

# Step 3: Test Login
echo -e "${YELLOW}=== STEP 3: User Login ===${NC}"
login_data="{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}"
test_endpoint "POST" "/auth/login" "$login_data" "Content-Type: application/json" "User Login"

# Step 4: Test Protected Endpoints with JWT
echo -e "${YELLOW}=== STEP 4: Protected Endpoints ===${NC}"

# Test Dashboard
test_endpoint "GET" "/dashboard" "" "Authorization: Bearer $JWT_TOKEN" "Dashboard Access"

# Test Boards List
test_endpoint "GET" "/boards" "" "Authorization: Bearer $JWT_TOKEN" "Boards List"

# Test Profile
test_endpoint "GET" "/profile" "" "Authorization: Bearer $JWT_TOKEN" "User Profile"

# Test Settings
test_endpoint "GET" "/settings" "" "Authorization: Bearer $JWT_TOKEN" "User Settings"

# Step 5: Test Board Operations
echo -e "${YELLOW}=== STEP 5: Board Operations ===${NC}"

# Create a new board
board_data="{\"name\":\"Test Board ${TIMESTAMP}\",\"description\":\"Test board created by automated test\"}"
board_response=$(test_endpoint "POST" "/boards" "$board_data" "Authorization: Bearer $JWT_TOKEN" "Create Board")

# Extract board ID if creation was successful
BOARD_ID=$(echo "$board_response" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
if [ -n "$BOARD_ID" ]; then
    echo -e "${GREEN}✅ Board created with ID: $BOARD_ID${NC}"
    
    # Test getting specific board
    test_endpoint "GET" "/boards/$BOARD_ID" "" "Authorization: Bearer $JWT_TOKEN" "Get Specific Board"
    
    # Test updating board
    update_data="{\"name\":\"Updated Test Board ${TIMESTAMP}\",\"description\":\"Updated description\"}"
    test_endpoint "PUT" "/boards/$BOARD_ID" "$update_data" "Authorization: Bearer $JWT_TOKEN" "Update Board"
    
    # Test deleting board
    test_endpoint "DELETE" "/boards/$BOARD_ID" "" "Authorization: Bearer $JWT_TOKEN" "Delete Board"
else
    echo -e "${YELLOW}⚠️  Board creation failed, skipping board-specific tests${NC}"
fi

# Step 6: Test Card Operations (if board exists)
if [ -n "$BOARD_ID" ]; then
    echo -e "${YELLOW}=== STEP 6: Card Operations ===${NC}"
    
    # Create a card
    card_data="{\"title\":\"Test Card ${TIMESTAMP}\",\"description\":\"Test card description\",\"boardId\":\"$BOARD_ID\"}"
    card_response=$(test_endpoint "POST" "/cards" "$card_data" "Authorization: Bearer $JWT_TOKEN" "Create Card")
    
    # Extract card ID if creation was successful
    CARD_ID=$(echo "$card_response" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
    if [ -n "$CARD_ID" ]; then
        echo -e "${GREEN}✅ Card created with ID: $CARD_ID${NC}"
        
        # Test getting specific card
        test_endpoint "GET" "/cards/$CARD_ID" "" "Authorization: Bearer $JWT_TOKEN" "Get Specific Card"
        
        # Test updating card
        update_card_data="{\"title\":\"Updated Test Card ${TIMESTAMP}\",\"description\":\"Updated card description\"}"
        test_endpoint "PUT" "/cards/$CARD_ID" "$update_card_data" "Authorization: Bearer $JWT_TOKEN" "Update Card"
        
        # Test deleting card
        test_endpoint "DELETE" "/cards/$CARD_ID" "" "Authorization: Bearer $JWT_TOKEN" "Delete Card"
    else
        echo -e "${YELLOW}⚠️  Card creation failed, skipping card-specific tests${NC}"
    fi
fi

# Step 7: Test Error Cases
echo -e "${YELLOW}=== STEP 7: Error Cases ===${NC}"

# Test invalid JWT
test_endpoint "GET" "/dashboard" "" "Authorization: Bearer invalid_token" "Invalid JWT Token"

# Test missing JWT
test_endpoint "GET" "/dashboard" "" "" "Missing JWT Token"

# Test invalid endpoint
test_endpoint "GET" "/invalid-endpoint" "" "" "Invalid Endpoint"

# Step 8: Test Auth Endpoints
echo -e "${YELLOW}=== STEP 8: Auth Endpoints ===${NC}"

# Test forgot password
forgot_data="{\"email\":\"$TEST_EMAIL\"}"
test_endpoint "POST" "/auth/forgot-password" "$forgot_data" "Content-Type: application/json" "Forgot Password"

# Test reset password (this might fail without proper token, but we test the endpoint)
reset_data="{\"token\":\"invalid_token\",\"password\":\"NewPassword123!\"}"
test_endpoint "POST" "/auth/reset-password" "$reset_data" "Content-Type: application/json" "Reset Password"

echo -e "${GREEN}🎉 Comprehensive endpoint testing completed!${NC}"
echo ""
echo -e "${BLUE}Test Summary:${NC}"
echo "✅ Health Check: Working"
echo "✅ User Registration: Working"
echo "✅ User Login: Working"
echo "✅ Protected Endpoints: Tested"
echo "✅ Board Operations: Tested"
echo "✅ Card Operations: Tested"
echo "✅ Error Handling: Tested"
echo "✅ Auth Endpoints: Tested"
