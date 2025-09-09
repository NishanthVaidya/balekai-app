#!/bin/bash

echo "🚀 AWS Deployment Script for Balekai Backend"
echo "=============================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="balekai-backend"
REGION="us-east-1"  # Change this to your preferred region
ECR_REPOSITORY_NAME="balekai-backend"
APP_RUNNER_SERVICE_NAME="balekai-backend-service"

echo -e "${BLUE}Step 1: Building the Application${NC}"
echo "Building Spring Boot application..."
mvn clean package -DskipTests

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Build failed. Please fix the build issues first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build successful!${NC}"
echo ""

echo -e "${BLUE}Step 2: Setting up AWS ECR Repository${NC}"
echo "Creating ECR repository for Docker images..."

# Check if ECR repository exists, create if not
aws ecr describe-repositories --repository-names $ECR_REPOSITORY_NAME --region $REGION > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Creating ECR repository: $ECR_REPOSITORY_NAME"
    aws ecr create-repository --repository-name $ECR_REPOSITORY_NAME --region $REGION
else
    echo "ECR repository already exists: $ECR_REPOSITORY_NAME"
fi

# Get ECR login token
echo "Getting ECR login token..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.$REGION.amazonaws.com

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ ECR login failed. Please check your AWS credentials.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ ECR login successful!${NC}"
echo ""

echo -e "${BLUE}Step 3: Building and Pushing Docker Image${NC}"
echo "Building Docker image..."

# Get ECR repository URI
ECR_REPOSITORY_URI=$(aws ecr describe-repositories --repository-names $ECR_REPOSITORY_NAME --region $REGION --query 'repositories[0].repositoryUri' --output text)

# Build Docker image
docker build -f Dockerfile.prod -t $ECR_REPOSITORY_URI:latest .

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Docker build failed. Please check the Dockerfile.${NC}"
    exit 1
fi

echo "Pushing Docker image to ECR..."
docker push $ECR_REPOSITORY_URI:latest

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Docker push failed. Please check your ECR permissions.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker image pushed successfully!${NC}"
echo ""

echo -e "${BLUE}Step 4: Setting up AWS App Runner Service${NC}"
echo "Creating App Runner service..."

# Check if App Runner service exists
aws apprunner describe-service --service-arn arn:aws:apprunner:$REGION:$(aws sts get-caller-identity --query Account --output text):service/$APP_RUNNER_SERVICE_NAME --region $REGION > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "Creating App Runner service..."
    
    # Create App Runner service
    aws apprunner create-service \
        --service-name $APP_RUNNER_SERVICE_NAME \
        --source-configuration "{
            \"AuthenticationConfiguration\": {
                \"AccessRoleArn\": \"arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/AppRunnerECRAccessRole\"
            },
            \"ImageRepository\": {
                \"ImageIdentifier\": \"$ECR_REPOSITORY_URI:latest\",
                \"ImageConfiguration\": {
                    \"Port\": \"8080\"
                },
                \"ImageRepositoryType\": \"ECR\"
            }
        }" \
        --instance-configuration "{
            \"Cpu\": \"1024\",
            \"Memory\": \"2048\"
        }" \
        --region $REGION
else
    echo "App Runner service already exists. Updating..."
    
    # Update App Runner service
    aws apprunner update-service \
        --service-arn arn:aws:apprunner:$REGION:$(aws sts get-caller-identity --query Account --output text):service/$APP_RUNNER_SERVICE_NAME \
        --source-configuration "{
            \"AuthenticationConfiguration\": {
                \"AccessRoleArn\": \"arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/AppRunnerECRAccessRole\"
            },
            \"ImageRepository\": {
                \"ImageIdentifier\": \"$ECR_REPOSITORY_URI:latest\",
                \"ImageConfiguration\": {
                    \"Port\": \"8080\"
                },
                \"ImageRepositoryType\": \"ECR\"
            }
        }" \
        --region $REGION
fi

echo ""
echo -e "${YELLOW}⚠️  Important: You need to create the AppRunnerECRAccessRole IAM role manually${NC}"
echo "This role should have the following policies:"
echo "- AmazonEC2ContainerRegistryReadOnly"
echo "- AppRunnerECRAccessRole"
echo ""

echo -e "${BLUE}Step 5: Environment Variables Setup${NC}"
echo "You need to set the following environment variables in App Runner:"
echo ""
echo "SPRING_DATASOURCE_URL=jdbc:postgresql://your-rds-endpoint:5432/your-database"
echo "SPRING_DATASOURCE_USERNAME=your-db-username"
echo "SPRING_DATASOURCE_PASSWORD=your-db-password"
echo "JWT_SECRET=your-super-secret-jwt-key-here"
echo ""

echo -e "${BLUE}Step 6: Database Setup${NC}"
echo "You need to create an RDS PostgreSQL instance with:"
echo "- Database name: trelllo_db"
echo "- Username: your-db-username"
echo "- Password: your-db-password"
echo "- Security group allowing access from App Runner"
echo ""

echo -e "${GREEN}🎉 Deployment script completed!${NC}"
echo ""
echo "Next steps:"
echo "1. Create the IAM role mentioned above"
echo "2. Set up RDS PostgreSQL database"
echo "3. Configure environment variables in App Runner"
echo "4. Test the deployed application"
echo ""
echo "Your App Runner service will be available at:"
echo "https://$APP_RUNNER_SERVICE_NAME.$(aws apprunner describe-service --service-arn arn:aws:apprunner:$REGION:$(aws sts get-caller-identity --query Account --output text):service/$APP_RUNNER_SERVICE_NAME --region $REGION --query 'Service.ServiceUrl' --output text 2>/dev/null || echo 'pending')"
echo ""
echo "For manual deployment, you can also use the AWS Console:"
echo "1. Go to AWS App Runner"
echo "2. Create service"
echo "3. Choose 'Container registry'"
echo "4. Select ECR and your image"
echo "5. Configure environment variables"
echo "6. Deploy!"
