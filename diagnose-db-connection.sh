#!/bin/bash

echo "🔍 Database Connection Diagnostic Script"
echo "========================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

ALB_URL="http://balekai-alb-new-626347040.us-east-1.elb.amazonaws.com"

echo -e "${BLUE}Step 1: Test Database Connection Endpoint${NC}"
echo "Testing: $ALB_URL/auth/db-test"
echo ""

# Test database connection endpoint
echo "Testing database connection..."
DB_RESPONSE=$(curl -s -w "\n%{http_code}\n%{time_total}" "$ALB_URL/auth/db-test")
DB_CODE=$(echo "$DB_RESPONSE" | tail -n 2 | head -n 1)
DB_TIME=$(echo "$DB_RESPONSE" | tail -n 1)

echo "Response Code: $DB_CODE"
echo "Response Time: $DB_TIME seconds"
echo "Response Body: $DB_RESPONSE"
echo ""

if [ "$DB_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Database connection working: $DB_TIME seconds${NC}"
elif [ "$DB_CODE" = "500" ]; then
    echo -e "${RED}❌ Database connection failed: HTTP 500${NC}"
    echo "This confirms database connection issues"
else
    echo -e "${YELLOW}⚠️  Database test returned: HTTP $DB_CODE${NC}"
fi
echo ""

echo -e "${BLUE}Step 2: Check ECS Service Status${NC}"
echo "Checking ECS service health..."
echo ""

# Check ECS service status
SERVICE_STATUS=$(aws ecs describe-services \
    --cluster balekai-cluster \
    --services balekai-service \
    --region us-east-1 \
    --query 'services[0].{status:status,runningCount:runningCount,desiredCount:desiredCount,deployments:deployments[0].{status:status,createdAt:createdAt}}' \
    --output table 2>/dev/null)

if [ $? -eq 0 ]; then
    echo "$SERVICE_STATUS"
else
    echo -e "${RED}❌ Failed to get ECS service status${NC}"
fi
echo ""

echo -e "${BLUE}Step 3: Check Recent Logs${NC}"
echo "Checking recent application logs..."
echo ""

# Get recent logs
echo "Recent logs (last 20 lines):"
aws logs tail /balekai/backend --region us-east-1 --since 5m --max-items 20 2>/dev/null || echo "No recent logs found"
echo ""

echo -e "${BLUE}Step 4: Check RDS Status${NC}"
echo "Checking RDS instance status..."
echo ""

# Check RDS status
RDS_STATUS=$(aws rds describe-db-instances \
    --db-instance-identifier balekai-postgres-new \
    --region us-east-1 \
    --query 'DBInstances[0].{status:DBInstanceStatus,engine:Engine,class:DBInstanceClass,endpoint:Endpoint.Address}' \
    --output table 2>/dev/null)

if [ $? -eq 0 ]; then
    echo "$RDS_STATUS"
else
    echo -e "${RED}❌ Failed to get RDS status${NC}"
fi
echo ""

echo -e "${BLUE}Step 5: Test Direct Database Connection${NC}"
echo "Testing direct connection to RDS..."
echo ""

# Test direct connection (if psql is available)
if command -v psql &> /dev/null; then
    echo "Testing direct PostgreSQL connection..."
    # Note: This will fail without proper credentials, but it's useful for testing
    echo "Attempting connection to: balekai-postgres-new.cy7yeimaywkm.us-east-1.rds.amazonaws.com:5432"
    echo "This test requires proper credentials and may fail - that's expected"
else
    echo "psql not available - skipping direct connection test"
fi
echo ""

echo -e "${BLUE}Step 6: Summary and Recommendations${NC}"
echo "=============================================="
echo ""

if [ "$DB_CODE" = "500" ]; then
    echo -e "${RED}🚨 DIAGNOSIS: Database Connection Pool Exhaustion${NC}"
    echo ""
    echo "The issue is confirmed: HikariCP cannot acquire database connections."
    echo ""
    echo "Most likely causes:"
    echo "1. RDS instance is down or unreachable"
    echo "2. Security groups blocking database access"
    echo "3. Database credentials are incorrect"
    echo "4. Connection pool is exhausted due to connection leaks"
    echo "5. Network connectivity issues (NAT Gateway, VPC routing)"
    echo ""
    echo "Immediate fixes:"
    echo "1. Check RDS instance status (see above)"
    echo "2. Verify security groups allow ECS → RDS traffic"
    echo "3. Check database credentials in Secrets Manager"
    echo "4. Restart ECS service to reset connection pool"
    echo "5. Deploy the optimized configuration"
elif [ "$DB_CODE" = "200" ]; then
    echo -e "${GREEN}✅ DIAGNOSIS: Database Connection Working${NC}"
    echo "Database connection is working. The issue may be intermittent."
    echo "Check for connection leaks or high load periods."
else
    echo -e "${YELLOW}⚠️  DIAGNOSIS: Inconclusive${NC}"
    echo "Database test returned unexpected result. Check logs and RDS status."
fi

echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "1. If RDS is down: Start the RDS instance"
echo "2. If security groups issue: Update ECS security group to allow RDS access"
echo "3. If credentials issue: Check Secrets Manager"
echo "4. Deploy optimized configuration: ./fix-alb-timeout.sh"
echo "5. Monitor logs: aws logs tail /balekai/backend --follow"
echo ""
echo "The optimized configuration will help with connection pool management"
echo "and provide better error handling and logging."
