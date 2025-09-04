#!/bin/bash

echo "🔧 Fixing ECS Configuration"
echo "============================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}Step 1: Creating JWT Secret${NC}"
echo "Creating JWT secret in AWS Secrets Manager..."

# Generate a secure JWT secret
JWT_SECRET=$(openssl rand -base64 32)

# Create the JWT secret
aws secretsmanager create-secret \
    --name "balekai-jwt-secret" \
    --description "JWT secret for Balekai backend" \
    --secret-string "$JWT_SECRET" \
    --region us-east-1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ JWT secret created successfully${NC}"
else
    echo -e "${YELLOW}⚠️  JWT secret might already exist, continuing...${NC}"
fi

echo ""
echo -e "${BLUE}Step 2: Updating Task Definition${NC}"
echo "Creating new task definition with JWT_SECRET..."

# Get the current task definition
CURRENT_TASK_DEF=$(aws ecs describe-task-definition --task-definition balekai-task-new:5 --region us-east-1)

# Create new task definition JSON with JWT_SECRET, handling tags properly
NEW_TASK_DEF=$(echo "$CURRENT_TASK_DEF" | jq --arg JWT_SECRET_ARN "arn:aws:secretsmanager:us-east-1:422456985301:secret:balekai-jwt-secret" '
.taskDefinition | 
.containerDefinitions[0].secrets += [{"name": "JWT_SECRET", "valueFrom": $JWT_SECRET_ARN}] |
{family: .family, 
 networkMode: .networkMode,
 requiresCompatibilities: .requiresCompatibilities,
 cpu: .cpu,
 memory: .memory,
 executionRoleArn: .executionRoleArn,
 taskRoleArn: .taskRoleArn,
 containerDefinitions: .containerDefinitions,
 volumes: .volumes,
 placementConstraints: .placementConstraints}')

# Save to file
echo "$NEW_TASK_DEF" > new-task-definition.json

echo "New task definition saved to new-task-definition.json"
echo ""

echo -e "${BLUE}Step 3: Register New Task Definition${NC}"
echo "Registering new task definition..."

NEW_TASK_DEF_ARN=$(aws ecs register-task-definition \
    --cli-input-json file://new-task-definition.json \
    --region us-east-1 \
    --query 'taskDefinition.taskDefinitionArn' \
    --output text)

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ New task definition registered: $NEW_TASK_DEF_ARN${NC}"
else
    echo -e "${YELLOW}❌ Failed to register task definition${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}Step 4: Update ECS Service${NC}"
echo "Updating service to use new task definition..."

aws ecs update-service \
    --cluster balekai-cluster-new \
    --service balekai-service-new \
    --task-definition "$NEW_TASK_DEF_ARN" \
    --force-new-deployment \
    --region us-east-1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Service updated successfully${NC}"
    echo ""
    echo -e "${YELLOW}⏳ Waiting for deployment to complete...${NC}"
    echo "This may take a few minutes..."
    echo ""
    echo "You can monitor the deployment with:"
    echo "aws ecs describe-services --cluster balekai-cluster-new --services balekai-service-new --region us-east-1"
else
    echo -e "${YELLOW}❌ Failed to update service${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 ECS Configuration Fixed!${NC}"
echo ""
echo "📋 What was fixed:"
echo "✅ Added JWT_SECRET environment variable"
echo "✅ Created secure JWT secret in Secrets Manager"
echo "✅ Updated task definition"
echo "✅ Updated ECS service"
echo ""
echo "🔍 Next steps:"
echo "1. Wait for deployment to complete"
echo "2. Check service status"
echo "3. Test the application endpoints"
echo "4. Update frontend to use the new ECS URL"
