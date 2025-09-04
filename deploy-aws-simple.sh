#!/bin/bash

echo "🚀 Simple AWS Deployment for Balekai Backend"
echo "============================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}Step 1: Building Application${NC}"
mvn clean package -DskipTests

if [ $? -ne 0 ]; then
    echo "❌ Build failed. Please fix the build issues first."
    exit 1
fi

echo -e "${GREEN}✅ Build successful!${NC}"
echo ""

echo -e "${BLUE}Step 2: Building Docker Image${NC}"
docker build -f Dockerfile.prod -t balekai-backend .

if [ $? -ne 0 ]; then
    echo "❌ Docker build failed."
    exit 1
fi

echo -e "${GREEN}✅ Docker image built successfully!${NC}"
echo ""

echo -e "${YELLOW}🎯 Next Steps for AWS Deployment:${NC}"
echo ""
echo "1. 📦 Push to AWS ECR:"
echo "   aws ecr create-repository --repository-name balekai-backend"
echo "   aws ecr get-login-password | docker login --username AWS --password-stdin <account>.dkr.ecr.<region>.amazonaws.com"
echo "   docker tag balekai-backend:latest <account>.dkr.ecr.<region>.amazonaws.com/balekai-backend:latest"
echo "   docker push <account>.dkr.ecr.<region>.amazonaws.com/balekai-backend:latest"
echo ""
echo "2. 🚀 Deploy to AWS App Runner:"
echo "   - Go to AWS App Runner Console"
echo "   - Create service"
echo "   - Choose 'Container registry'"
echo "   - Select ECR and your image"
echo "   - Set environment variables:"
echo "     SPRING_DATASOURCE_URL=jdbc:postgresql://your-rds-endpoint:5432/trelllo_db"
echo "     SPRING_DATASOURCE_USERNAME=your-db-username"
echo "     SPRING_DATASOURCE_PASSWORD=your-db-password"
echo "     JWT_SECRET=your-super-secret-jwt-key"
echo ""
echo "3. 🗄️ Set up RDS PostgreSQL:"
echo "   - Create RDS instance"
echo "   - Database name: trelllo_db"
echo "   - Configure security groups"
echo ""
echo "4. 🔗 Update Frontend:"
echo "   - Change API endpoints to your AWS App Runner URL"
echo "   - Test all functionality"
echo ""
echo -e "${GREEN}🎉 Your backend is ready for AWS deployment!${NC}"
echo ""
echo "📋 For detailed deployment steps, see: AWS_DEPLOYMENT_CHECKLIST.md"
echo "🛡️ Your changes are backed up in: backend-backup-*/"
