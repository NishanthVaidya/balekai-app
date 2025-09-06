#!/bin/bash

echo "🔍 ALB Timeout Debugging Script"
echo "================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

ALB_URL="http://balekai-alb-new-626347040.us-east-1.elb.amazonaws.com"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo -e "${BLUE}Step 1: Test Health Endpoint${NC}"
echo "Testing: $ALB_URL/health"
echo "Timestamp: $TIMESTAMP"
echo ""

# Test health endpoint first
echo "Testing health endpoint..."
HEALTH_RESPONSE=$(curl -s -w "\n%{http_code}\n%{time_total}" "$ALB_URL/health")
HEALTH_CODE=$(echo "$HEALTH_RESPONSE" | tail -n 2 | head -n 1)
HEALTH_TIME=$(echo "$HEALTH_RESPONSE" | tail -n 1)

if [ "$HEALTH_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Health endpoint working: $HEALTH_TIME seconds${NC}"
else
    echo -e "${RED}❌ Health endpoint failed: HTTP $HEALTH_CODE${NC}"
    echo "Response: $HEALTH_RESPONSE"
fi
echo ""

echo -e "${BLUE}Step 2: Test Auth Register with Detailed Timing${NC}"
echo "Testing: $ALB_URL/auth/register"
echo ""

# Test register endpoint with detailed timing
echo "Testing register endpoint..."
REGISTER_RESPONSE=$(curl -s -w "\n%{http_code}\n%{time_total}\n%{time_connect}\n%{time_starttransfer}" \
    -H "Content-Type: application/json" \
    -d '{"email":"debug-test-'$(date +%s)'@balekai.com","password":"TestPassword123!","name":"Debug Test"}' \
    "$ALB_URL/auth/register" 2>&1)

REGISTER_CODE=$(echo "$REGISTER_RESPONSE" | tail -n 4 | head -n 1)
REGISTER_TIME=$(echo "$REGISTER_RESPONSE" | tail -n 3 | head -n 1)
REGISTER_CONNECT=$(echo "$REGISTER_RESPONSE" | tail -n 2 | head -n 1)
REGISTER_START=$(echo "$REGISTER_RESPONSE" | tail -n 1)

echo "Response Code: $REGISTER_CODE"
echo "Total Time: $REGISTER_TIME seconds"
echo "Connect Time: $REGISTER_CONNECT seconds"
echo "Start Transfer Time: $REGISTER_START seconds"
echo ""

if [ "$REGISTER_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Register endpoint working: $REGISTER_TIME seconds${NC}"
elif [ "$REGISTER_CODE" = "000" ]; then
    echo -e "${RED}❌ Register endpoint timed out (>60s)${NC}"
    echo "This indicates ALB timeout or application hang"
else
    echo -e "${YELLOW}⚠️  Register endpoint returned: HTTP $REGISTER_CODE${NC}"
    echo "Response: $REGISTER_RESPONSE"
fi
echo ""

echo -e "${BLUE}Step 3: Test Debug Endpoint (if available)${NC}"
echo "Testing: $ALB_URL/auth/register-debug"
echo ""

# Test debug endpoint
DEBUG_RESPONSE=$(curl -s -w "\n%{http_code}\n%{time_total}" \
    -H "Content-Type: application/json" \
    -d '{"email":"debug-test-'$(date +%s)'@balekai.com","password":"TestPassword123!","name":"Debug Test"}' \
    "$ALB_URL/auth/register-debug" 2>&1)

DEBUG_CODE=$(echo "$DEBUG_RESPONSE" | tail -n 2 | head -n 1)
DEBUG_TIME=$(echo "$DEBUG_RESPONSE" | tail -n 1)

if [ "$DEBUG_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Debug endpoint working: $DEBUG_TIME seconds${NC}"
elif [ "$DEBUG_CODE" = "404" ]; then
    echo -e "${YELLOW}⚠️  Debug endpoint not found (expected)${NC}"
else
    echo -e "${RED}❌ Debug endpoint failed: HTTP $DEBUG_CODE${NC}"
fi
echo ""

echo -e "${BLUE}Step 4: Test with Different Password Complexity${NC}"
echo "Testing with simple password..."
echo ""

# Test with simple password
SIMPLE_RESPONSE=$(curl -s -w "\n%{http_code}\n%{time_total}" \
    -H "Content-Type: application/json" \
    -d '{"email":"simple-test-'$(date +%s)'@balekai.com","password":"123456","name":"Simple Test"}' \
    "$ALB_URL/auth/register" 2>&1)

SIMPLE_CODE=$(echo "$SIMPLE_RESPONSE" | tail -n 2 | head -n 1)
SIMPLE_TIME=$(echo "$SIMPLE_RESPONSE" | tail -n 1)

echo "Simple Password Response Code: $SIMPLE_CODE"
echo "Simple Password Time: $SIMPLE_TIME seconds"
echo ""

echo -e "${BLUE}Step 5: Summary and Recommendations${NC}"
echo "=============================================="
echo ""

if [ "$HEALTH_CODE" = "200" ] && [ "$REGISTER_CODE" = "000" ]; then
    echo -e "${RED}🚨 DIAGNOSIS: Application Hang${NC}"
    echo "Health endpoint works but register times out."
    echo "This indicates the /auth/register handler is hanging."
    echo ""
    echo "Most likely causes:"
    echo "1. BCrypt hashing taking too long (cost too high)"
    echo "2. Database connection issues"
    echo "3. Container resource constraints"
    echo ""
    echo "Immediate fixes:"
    echo "1. Reduce BCrypt cost to 8-10"
    echo "2. Increase container CPU/memory"
    echo "3. Add request timeouts"
    echo "4. Add comprehensive logging"
elif [ "$HEALTH_CODE" = "200" ] && [ "$REGISTER_CODE" = "200" ]; then
    echo -e "${GREEN}✅ DIAGNOSIS: Working${NC}"
    echo "Both endpoints working. Issue may be intermittent."
    echo "Check ALB access logs for patterns."
elif [ "$HEALTH_CODE" != "200" ]; then
    echo -e "${RED}🚨 DIAGNOSIS: Infrastructure Issue${NC}"
    echo "Health endpoint failing. Check:"
    echo "1. ALB target group health"
    echo "2. ECS service status"
    echo "3. Container logs"
fi

echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "1. Check ECS service logs: aws logs tail /balekai/backend --follow"
echo "2. Check ALB access logs for request patterns"
echo "3. Implement the fixes in the next script"
echo "4. Test with the debug endpoint"
echo ""
echo "Run this script again after implementing fixes to verify improvements."
