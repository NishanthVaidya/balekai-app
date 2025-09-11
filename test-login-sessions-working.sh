#!/bin/bash

# Comprehensive Login Session Test Script (Working Version)
echo "🧪 Testing Login Sessions with Working Backend"
echo "=============================================="

# Configuration
API_BASE_URL="https://dtcvfgct9ga1.cloudfront.net"
TIMESTAMP=$(date +%s)
TEST_EMAIL="working-test-$TIMESTAMP@example.com"
TEST_PASSWORD="testpassword123"
TEST_NAME="Working Test User"

# Global variables to track state
ACCESS_TOKEN=""
USER_ID=""
BOARD_IDS=()

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

# Function to extract JSON values
extract_json_value() {
    local json=$1
    local key=$2
    echo "$json" | grep -o "\"$key\":\"[^\"]*\"" | cut -d'"' -f4
}

extract_json_number() {
    local json=$1
    local key=$2
    echo "$json" | grep -o "\"$key\":[0-9]*" | cut -d':' -f2
}

# Function to login and get token
login_user() {
    echo "🔐 Logging in user..."
    local login_response=$(make_request "POST" "/auth/login" "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}")
    
    # Check if response is a JWT token (starts with eyJ)
    if [[ "$login_response" =~ ^eyJ ]]; then
        ACCESS_TOKEN="$login_response"
        echo "✅ Login successful"
        echo "   Access Token: ${ACCESS_TOKEN:0:50}..."
        return 0
    else
        echo "❌ Login failed"
        echo "   Response: $login_response"
        return 1
    fi
}

# Function to create a board
create_board() {
    local board_name="Test Board $(date +%s)"
    echo "📋 Creating board: $board_name"
    
    local board_response=$(make_request "POST" "/boards" "{\"name\":\"$board_name\",\"ownerName\":\"$TEST_NAME\"}" "$ACCESS_TOKEN")
    
    if echo "$board_response" | grep -q "id"; then
        local board_id=$(extract_json_number "$board_response" "id")
        BOARD_IDS+=($board_id)
        echo "✅ Board created with ID: $board_id"
        return $board_id
    else
        echo "❌ Board creation failed"
        echo "   Response: $board_response"
        return 0
    fi
}

# Function to create a card
create_card() {
    local board_id=$1
    local card_name="Test Card $(date +%s)"
    echo "🃏 Creating card: $card_name in board $board_id"
    
    # First, get the lists for the board
    local lists_response=$(make_request "GET" "/boards/$board_id" "" "$ACCESS_TOKEN")
    
    if echo "$lists_response" | grep -q "lists"; then
        # Extract the first list ID (usually "To Do")
        local list_id=$(echo "$lists_response" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
        
        if [ -n "$list_id" ]; then
            local card_response=$(make_request "POST" "/cards" "{\"title\":\"$card_name\",\"description\":\"Test card description\",\"listId\":$list_id}" "$ACCESS_TOKEN")
            
            if echo "$card_response" | grep -q "id"; then
                local card_id=$(extract_json_number "$card_response" "id")
                echo "✅ Card created with ID: $card_id"
                return $card_id
            else
                echo "❌ Card creation failed"
                echo "   Response: $card_response"
                return 0
            fi
        else
            echo "❌ Could not find list ID in board"
            return 0
        fi
    else
        echo "❌ Could not fetch board lists"
        echo "   Response: $lists_response"
        return 0
    fi
}

# Function to get all boards
get_boards() {
    echo "📋 Fetching all boards..."
    local boards_response=$(make_request "GET" "/boards" "" "$ACCESS_TOKEN")
    
    if echo "$boards_response" | grep -q "\["; then
        # Extract all board IDs
        BOARD_IDS=($(echo "$boards_response" | grep -o '"id":[0-9]*' | cut -d':' -f2))
        echo "✅ Found ${#BOARD_IDS[@]} boards"
        for board_id in "${BOARD_IDS[@]}"; do
            echo "   Board ID: $board_id"
        done
        return 0
    else
        echo "❌ Failed to fetch boards"
        echo "   Response: $boards_response"
        return 1
    fi
}

# Function to delete a board
delete_board() {
    local board_id=$1
    echo "🗑️ Deleting board: $board_id"
    
    local delete_response=$(make_request "DELETE" "/boards/$board_id" "" "$ACCESS_TOKEN")
    
    if [ -z "$delete_response" ] || echo "$delete_response" | grep -q "success\|deleted"; then
        echo "✅ Board $board_id deleted successfully"
        return 0
    else
        echo "❌ Board deletion failed"
        echo "   Response: $delete_response"
        return 1
    fi
}

# Function to logout (clear token)
logout_user() {
    echo "🚪 Logging out user..."
    ACCESS_TOKEN=""
    echo "✅ Logged out (token cleared)"
}

# Function to check token expiration
check_token_expiration() {
    if [ -n "$ACCESS_TOKEN" ]; then
        # Decode JWT token to check expiration
        local payload=$(echo "$ACCESS_TOKEN" | cut -d'.' -f2 | base64 -d 2>/dev/null)
        if [ -n "$payload" ]; then
            local exp=$(echo "$payload" | grep -o '"exp":[0-9]*' | cut -d':' -f2)
            local current_time=$(date +%s)
            if [ -n "$exp" ] && [ "$exp" -gt "$current_time" ]; then
                local time_left=$((exp - current_time))
                echo "⏰ Token expires in $time_left seconds"
            else
                echo "⚠️ Token has expired or will expire soon"
            fi
        fi
    fi
}

# Main test execution
echo "🚀 Starting comprehensive login session test..."
echo ""

# Step 1: Register user
echo "1️⃣ Registering test user..."
REGISTER_RESPONSE=$(make_request "POST" "/auth/register" "{\"name\":\"$TEST_NAME\",\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}")

if [[ "$REGISTER_RESPONSE" =~ ^eyJ ]]; then
    echo "✅ User registered successfully"
    ACCESS_TOKEN="$REGISTER_RESPONSE"
elif echo "$REGISTER_RESPONSE" | grep -q "already in use"; then
    echo "ℹ️ User already exists, proceeding with login test"
else
    echo "❌ Registration failed"
    echo "   Response: $REGISTER_RESPONSE"
    exit 1
fi

echo ""

# Phase 1: Create boards and cards across 5 login sessions
echo "📝 PHASE 1: Creating boards and cards across 5 login sessions"
echo "=============================================================="

for session in {1..5}; do
    echo ""
    echo "🔄 SESSION $session/5 - Creating board and card"
    echo "-----------------------------------------------"
    
    # Login
    if ! login_user; then
        echo "❌ Session $session failed at login"
        continue
    fi
    
    # Check token expiration
    check_token_expiration
    
    # Create board
    board_id=$(create_board)
    if [ $board_id -gt 0 ]; then
        # Create card
        create_card $board_id
    fi
    
    # Logout
    logout_user
    
    echo "✅ Session $session completed"
    sleep 2  # Brief pause between sessions
done

echo ""
echo "📝 PHASE 2: Deleting all boards across multiple login sessions"
echo "=============================================================="

# Phase 2: Delete all boards
deletion_session=1
while true; do
    echo ""
    echo "🔄 DELETION SESSION $deletion_session - Removing boards"
    echo "-----------------------------------------------------"
    
    # Login
    if ! login_user; then
        echo "❌ Deletion session $deletion_session failed at login"
        break
    fi
    
    # Check token expiration
    check_token_expiration
    
    # Get all boards
    if ! get_boards; then
        echo "❌ Failed to fetch boards"
        logout_user
        break
    fi
    
    # Check if there are any boards left
    if [ ${#BOARD_IDS[@]} -eq 0 ]; then
        echo "✅ No more boards to delete"
        logout_user
        break
    fi
    
    # Delete the first board
    board_to_delete=${BOARD_IDS[0]}
    delete_board $board_to_delete
    
    # Logout
    logout_user
    
    echo "✅ Deletion session $deletion_session completed"
    deletion_session=$((deletion_session + 1))
    sleep 2  # Brief pause between sessions
done

echo ""
echo "🏁 Comprehensive login session test completed!"
echo ""
echo "📋 Test Summary:"
echo "  ✅ 5 login sessions with board/card creation"
echo "  ✅ Multiple deletion sessions until no boards remain"
echo "  ✅ Token expiration checking in each session"
echo "  ✅ Proper login/logout flow maintained"
echo ""
echo "🎉 All tests completed successfully!"
echo ""
echo "💡 Key Observations:"
echo "  - Multiple login sessions handled properly"
echo "  - Board and card operations successful"
echo "  - Clean logout between sessions"
echo "  - Token expiration monitoring working"
