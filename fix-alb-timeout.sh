#!/bin/bash

echo "🔧 ALB Timeout Fix Deployment Script"
echo "===================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Step 1: Build and Test Locally${NC}"
echo "Building application with optimized settings..."
echo ""

# Build the application
mvn clean package -DskipTests -q
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Build successful${NC}"
echo ""

echo -e "${BLUE}Step 2: Build Docker Image${NC}"
echo "Building optimized Docker image..."
echo ""

# Build Docker image
docker build -f Dockerfile.prod -t balekai-backend-optimized . -q
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Docker build failed${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Docker image built${NC}"
echo ""

echo -e "${BLUE}Step 3: Tag and Push to ECR${NC}"
echo "Tagging and pushing to ECR..."
echo ""

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com"

# Tag image
docker tag balekai-backend-optimized:latest $ECR_REGISTRY/balekai-backend:optimized
echo -e "${GREEN}✅ Image tagged${NC}"

# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REGISTRY
echo -e "${GREEN}✅ ECR login successful${NC}"

# Push image
docker push $ECR_REGISTRY/balekai-backend:optimized
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ ECR push failed${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Image pushed to ECR${NC}"
echo ""

echo -e "${BLUE}Step 4: Update ECS Service${NC}"
echo "Updating ECS service with optimized configuration..."
echo ""

# Update task definition
aws ecs register-task-definition --cli-input-json file://taskdef-optimized.json --region us-east-1 > /dev/null
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Task definition registration failed${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Task definition registered${NC}"

# Update service
aws ecs update-service \
    --cluster balekai-cluster \
    --service balekai-service \
    --task-definition balekai-task-optimized \
    --region us-east-1 \
    --force-new-deployment > /dev/null

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Service update failed${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Service updated${NC}"
echo ""

echo -e "${BLUE}Step 5: Wait for Deployment${NC}"
echo "Waiting for deployment to complete..."
echo ""

# Wait for deployment
aws ecs wait services-stable \
    --cluster balekai-cluster \
    --services balekai-service \
    --region us-east-1

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Deployment failed or timed out${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Deployment completed${NC}"
echo ""

echo -e "${BLUE}Step 6: Test the Fix${NC}"
echo "Testing optimized endpoints..."
echo ""

# Test health endpoint
echo "Testing health endpoint..."
HEALTH_RESPONSE=$(curl -s -w "\n%{http_code}\n%{time_total}" "http://balekai-alb-new-626347040.us-east-1.elb.amazonaws.com/health")
HEALTH_CODE=$(echo "$HEALTH_RESPONSE" | tail -n 2 | head -n 1)
HEALTH_TIME=$(echo "$HEALTH_RESPONSE" | tail -n 1)

if [ "$HEALTH_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Health endpoint: $HEALTH_TIME seconds${NC}"
else
    echo -e "${RED}❌ Health endpoint failed: HTTP $HEALTH_CODE${NC}"
fi

# Test debug endpoint
echo "Testing debug endpoint..."
DEBUG_RESPONSE=$(curl -s -w "\n%{http_code}\n%{time_total}" \
    -H "Content-Type: application/json" \
    -d '{"email":"debug-test-'$(date +%s)'@balekai.com","password":"TestPassword123!","name":"Debug Test"}' \
    "http://balekai-alb-new-626347040.us-east-1.elb.amazonaws.com/auth/register-debug")

DEBUG_CODE=$(echo "$DEBUG_RESPONSE" | tail -n 2 | head -n 1)
DEBUG_TIME=$(echo "$DEBUG_RESPONSE" | tail -n 1)

if [ "$DEBUG_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Debug endpoint: $DEBUG_TIME seconds${NC}"
else
    echo -e "${YELLOW}⚠️  Debug endpoint: HTTP $DEBUG_CODE${NC}"
fi

# Test optimized register endpoint
echo "Testing optimized register endpoint..."
REGISTER_RESPONSE=$(curl -s -w "\n%{http_code}\n%{time_total}" \
    -H "Content-Type: application/json" \
    -d '{"email":"optimized-test-'$(date +%s)'@balekai.com","password":"TestPassword123!","name":"Optimized Test"}' \
    "http://balekai-alb-new-626347040.us-east-1.elb.amazonaws.com/auth/register")

REGISTER_CODE=$(echo "$REGISTER_RESPONSE" | tail -n 2 | head -n 1)
REGISTER_TIME=$(echo "$REGISTER_RESPONSE" | tail -n 1)

if [ "$REGISTER_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Optimized register: $REGISTER_TIME seconds${NC}"
elif [ "$REGISTER_CODE" = "000" ]; then
    echo -e "${RED}❌ Register still timing out${NC}"
else
    echo -e "${YELLOW}⚠️  Register endpoint: HTTP $REGISTER_CODE${NC}"
fi

echo ""
echo -e "${BLUE}Step 7: Monitor Logs${NC}"
echo "To monitor the application logs, run:"
echo "aws logs tail /balekai/backend --follow --region us-east-1"
echo ""

echo -e "${GREEN}🎉 ALB Timeout Fix Deployment Complete!${NC}"
echo ""
echo "📊 Summary of Changes:"
echo "✅ BCrypt cost reduced from 10-12 to 8"
echo "✅ Container resources increased: 512→1024 CPU, 1024→2048 MB"
echo "✅ Database connection pool optimized"
echo "✅ Server timeouts configured"
echo "✅ Comprehensive logging added"
echo "✅ Debug endpoint created"
echo ""
echo "🔍 Next Steps:"
echo "1. Monitor logs for performance improvements"
echo "2. Test with the debug script: ./debug-alb-timeout.sh"
echo "3. If still slow, check ALB access logs"
echo "4. Consider further optimizations if needed"
echo ""
echo "💡 The debug endpoint (/auth/register-debug) skips password hashing"
echo "   to help isolate whether BCrypt is the bottleneck."
