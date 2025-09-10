#!/bin/bash

# Fix JWT and Privacy Issues Script
# This script deploys the fixes for JWT validation and privacy filtering

set -e

echo "🔧 Fixing JWT and Privacy Issues..."

# Step 1: Build and push the updated Docker image
echo "📦 Building updated Docker image..."
docker build -t balekai-backend:latest .
docker tag balekai-backend:latest 422456985301.dkr.ecr.us-east-1.amazonaws.com/balekai-backend:latest

echo "🚀 Pushing to ECR..."
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 422456985301.dkr.ecr.us-east-1.amazonaws.com
docker push 422456985301.dkr.ecr.us-east-1.amazonaws.com/balekai-backend:latest

# Step 2: Update ECS task definition with JWT_SECRET
echo "📝 Updating ECS task definition with JWT_SECRET..."
aws ecs register-task-definition --cli-input-json file://new-task-definition.json

# Step 3: Update ECS service to use new task definition
echo "🔄 Updating ECS service..."
TASK_DEFINITION_ARN=$(aws ecs describe-task-definition --task-definition balekai-task --query 'taskDefinition.taskDefinitionArn' --output text)
aws ecs update-service --cluster balekai-cluster --service balekai-service --task-definition $TASK_DEFINITION_ARN

echo "⏳ Waiting for service to stabilize..."
aws ecs wait services-stable --cluster balekai-cluster --services balekai-service

echo "✅ Deployment complete! JWT and privacy issues should now be fixed."
echo ""
echo "🔍 Testing the fixes..."
echo "1. JWT validation should now work for POST requests"
echo "2. Privacy filtering should properly show only user's own boards"
echo "3. Board creation should be functional"
echo ""
echo "📊 Check the logs with:"
echo "aws logs tail /balekai/backend --follow"
