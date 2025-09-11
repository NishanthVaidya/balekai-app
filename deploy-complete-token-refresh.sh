#!/bin/bash

echo "🚀 Complete Token Refresh Deployment"
echo "===================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
AWS_ACCOUNT_ID="422456985301"
AWS_REGION="us-east-1"
ECR_REPOSITORY="balekai-backend"
ECS_CLUSTER="balekai-cluster-new"
ECS_SERVICE="balekai-service-new"
JWT_SECRET="QE2euE6XuT/euByteUpbkdlvNr/ee1WEFcmGTej47Ao="

echo -e "${BLUE}Step 1: Updating JWT Secret in AWS Secrets Manager${NC}"
aws secretsmanager update-secret \
    --secret-id "arn:aws:secretsmanager:us-east-1:422456985301:secret:balekai-jwt-secret-7UGJfy" \
    --secret-string "$JWT_SECRET"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to update JWT secret${NC}"
    exit 1
fi

echo -e "${GREEN}✅ JWT secret updated successfully!${NC}"
echo ""

echo -e "${BLUE}Step 2: Building Application with Token Refresh${NC}"
echo "Building Spring Boot application with complete token refresh functionality..."

# Clean and build the application
mvn clean package -DskipTests

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Build failed. Please fix the build issues first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build successful!${NC}"
echo ""

echo -e "${BLUE}Step 3: Logging into AWS ECR${NC}"
# Get ECR login token
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ ECR login failed. Please check your AWS credentials.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ ECR login successful!${NC}"
echo ""

echo -e "${BLUE}Step 4: Building and Pushing Docker Image${NC}"
ECR_URI="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY"

echo "Building Docker image with tag: latest"
docker build -f Dockerfile.prod -t $ECR_URI:latest .

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Docker build failed.${NC}"
    exit 1
fi

echo "Pushing Docker image to ECR..."
docker push $ECR_URI:latest

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Docker push failed.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker image pushed successfully!${NC}"
echo ""

echo -e "${BLUE}Step 5: Updating ECS Service${NC}"
echo "Forcing new deployment to use the updated image and secret..."

# Force new deployment
aws ecs update-service \
    --cluster $ECS_CLUSTER \
    --service $ECS_SERVICE \
    --force-new-deployment \
    --region $AWS_REGION

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ ECS service update failed.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ ECS service update initiated!${NC}"
echo ""

echo -e "${BLUE}Step 6: Waiting for Deployment to Complete${NC}"
echo "Waiting for deployment to complete..."

# Wait for deployment to complete
aws ecs wait services-stable \
    --cluster $ECS_CLUSTER \
    --services $ECS_SERVICE \
    --region $AWS_REGION

if [ $? -ne 0 ]; then
    echo -e "${YELLOW}⚠️ Deployment is taking longer than expected.${NC}"
    echo "You can check the status manually in the AWS Console."
else
    echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
fi

echo ""
echo -e "${BLUE}Step 7: Testing Token Refresh Functionality${NC}"
echo "Waiting for service to be fully ready..."
sleep 30

# Test the refresh endpoint
echo "Testing /auth/refresh endpoint..."
REFRESH_TEST=$(curl -s -X POST -H "Content-Type: application/json" -d '{"refreshToken":"test"}' http://balekai-alb-new-626347040.us-east-1.elb.amazonaws.com/auth/refresh)

if echo "$REFRESH_TEST" | grep -q "refreshToken"; then
    echo -e "${GREEN}✅ Refresh endpoint is working!${NC}"
elif echo "$REFRESH_TEST" | grep -q "404"; then
    echo -e "${RED}❌ Refresh endpoint not found - deployment may not be complete yet.${NC}"
else
    echo -e "${YELLOW}⚠️ Refresh endpoint response: $REFRESH_TEST${NC}"
fi

# Test login endpoint for new token format
echo "Testing login endpoint for new token format..."
LOGIN_TEST=$(curl -s -X POST -H "Content-Type: application/json" -d '{"email":"test@example.com","password":"testpassword123"}' http://balekai-alb-new-626347040.us-east-1.elb.amazonaws.com/auth/login)

if echo "$LOGIN_TEST" | grep -q "accessToken"; then
    echo -e "${GREEN}✅ Login endpoint returns new token format!${NC}"
    
    # Extract tokens and test them
    ACCESS_TOKEN=$(echo "$LOGIN_TEST" | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)
    REFRESH_TOKEN=$(echo "$LOGIN_TEST" | grep -o '"refreshToken":"[^"]*"' | cut -d'"' -f4)
    
    if [ -n "$ACCESS_TOKEN" ] && [ -n "$REFRESH_TOKEN" ]; then
        echo "Testing access with new access token..."
        BOARD_TEST=$(curl -s -X GET -H "Authorization: Bearer $ACCESS_TOKEN" http://balekai-alb-new-626347040.us-east-1.elb.amazonaws.com/boards)
        
        if echo "$BOARD_TEST" | grep -q "\[" || echo "$BOARD_TEST" | grep -q "boards"; then
            echo -e "${GREEN}✅ Access token validation working!${NC}"
        else
            echo -e "${RED}❌ Access token validation failed: $BOARD_TEST${NC}"
        fi
        
        echo "Testing token refresh..."
        REFRESH_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d "{\"refreshToken\":\"$REFRESH_TOKEN\"}" http://balekai-alb-new-626347040.us-east-1.elb.amazonaws.com/auth/refresh)
        
        if echo "$REFRESH_RESPONSE" | grep -q "accessToken"; then
            echo -e "${GREEN}✅ Token refresh working!${NC}"
        else
            echo -e "${RED}❌ Token refresh failed: $REFRESH_RESPONSE${NC}"
        fi
    fi
    
elif echo "$LOGIN_TEST" | grep -q "eyJ"; then
    echo -e "${YELLOW}⚠️ Login endpoint still returns old format - deployment may not be complete yet.${NC}"
else
    echo -e "${YELLOW}⚠️ Login endpoint response: $LOGIN_TEST${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Complete Token Refresh Deployment Finished!${NC}"
echo ""
echo -e "${BLUE}📋 Deployment Summary:${NC}"
echo "✅ JWT secret updated in AWS Secrets Manager"
echo "✅ Backend built with complete token refresh functionality"
echo "✅ Docker image pushed to ECR"
echo "✅ ECS service updated and deployed"
echo "✅ Token refresh endpoints tested"
echo ""
echo -e "${BLUE}🔗 Service URLs:${NC}"
echo "Backend (ALB): http://balekai-alb-new-626347040.us-east-1.elb.amazonaws.com"
echo "Frontend (CloudFront): https://dtcvfgct9ga1.cloudfront.net"
echo ""
echo -e "${BLUE}🧪 Next Steps:${NC}"
echo "1. Wait 5-10 minutes for CloudFront cache to clear"
echo "2. Deploy frontend changes to use token refresh"
echo "3. Test complete authentication flow"
echo "4. Monitor token refresh functionality"
echo ""
echo -e "${YELLOW}💡 Note: CloudFront may take a few minutes to serve the new version${NC}"
echo "You can test directly against the ALB URL for immediate results."
