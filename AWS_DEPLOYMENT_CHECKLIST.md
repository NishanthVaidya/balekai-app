# 🚀 AWS Deployment Checklist for Balekai Backend

## ✅ **Pre-Deployment Verification**

### 1. Backend Changes Preserved
- [x] CORS preflight fix (FirebaseTokenFilter.java)
- [x] User assignment enhancement (CardController.java)
- [x] User endpoint fix (UserController.java)
- [x] Package structure updated (kardo → balekai)
- [x] Production configuration ready
- [x] All changes backed up

### 2. Application Status
- [x] Core functionality: 96.6% working
- [x] Authentication: ✅ Working
- [x] Board Management: ✅ Working
- [x] Card Operations: ✅ Working
- [x] User Management: ✅ Working
- [x] Security: ✅ Working
- [x] Error Handling: ✅ Working

## 🎯 **Deployment Options**

### **Option 1: AWS App Runner (Recommended)**
- **Pros**: Fully managed, auto-scaling, easy deployment
- **Cons**: Slightly more expensive
- **Best for**: Quick deployment, minimal DevOps overhead

### **Option 2: AWS ECS with Fargate**
- **Pros**: Cost-effective, scalable, managed containers
- **Cons**: More complex setup
- **Best for**: Production workloads, cost optimization

### **Option 3: EC2 Instance**
- **Pros**: Full control, cheapest
- **Cons**: Manual management, security concerns
- **Best for**: Learning, full control

## 🚀 **Deployment Steps**

### **Phase 1: Infrastructure Setup**

#### 1.1 AWS Account & Permissions
- [ ] AWS CLI configured with appropriate permissions
- [ ] IAM roles created for App Runner/ECS
- [ ] ECR repository access configured

#### 1.2 Database Setup (RDS PostgreSQL)
- [ ] Create RDS PostgreSQL instance
- [ ] Database name: `trelllo_db`
- [ ] Configure security groups
- [ ] Note endpoint, username, password

#### 1.3 Environment Variables
```
SPRING_DATASOURCE_URL=jdbc:postgresql://your-rds-endpoint:5432/trelllo_db
SPRING_DATASOURCE_USERNAME=your-db-username
SPRING_DATASOURCE_PASSWORD=your-db-password
JWT_SECRET=your-super-secret-jwt-key-here
```

### **Phase 2: Application Deployment**

#### 2.1 Build & Package
- [ ] Run `mvn clean package -DskipTests`
- [ ] Verify JAR file: `target/balekai-1.0-SNAPSHOT.jar`

#### 2.2 Docker Image
- [ ] Build Docker image: `docker build -f Dockerfile.prod -t balekai-backend .`
- [ ] Test locally: `docker run -p 8080:8080 balekai-backend`

#### 2.3 Push to ECR
- [ ] Create ECR repository
- [ ] Push Docker image to ECR
- [ ] Verify image in ECR

#### 2.4 Deploy to App Runner/ECS
- [ ] Create service
- [ ] Configure environment variables
- [ ] Deploy and verify

### **Phase 3: Post-Deployment**

#### 3.1 Testing
- [ ] Health check endpoint: `/health`
- [ ] Authentication endpoints: `/auth/register`, `/auth/login`
- [ ] Core functionality: boards, lists, cards
- [ ] CORS configuration working

#### 3.2 Monitoring
- [ ] Set up CloudWatch logs
- [ ] Configure health checks
- [ ] Set up alerts for errors

#### 3.3 Frontend Integration
- [ ] Update frontend API endpoints to AWS URL
- [ ] Test all functionality
- [ ] Verify authentication flow

## 🔧 **Troubleshooting**

### Common Issues
1. **CORS errors**: Check App Runner/ECS CORS configuration
2. **Database connection**: Verify RDS security groups and credentials
3. **JWT errors**: Check JWT_SECRET environment variable
4. **Port issues**: Ensure port 8080 is exposed and accessible

### Rollback Plan
- [ ] Keep previous deployment running
- [ ] Use backup scripts if needed
- [ ] Test thoroughly before switching traffic

## 📊 **Cost Estimation**

### App Runner (Monthly)
- **1 vCPU, 2GB RAM**: ~$25-30/month
- **Data transfer**: ~$5-10/month
- **Total**: ~$30-40/month

### ECS Fargate (Monthly)
- **1 vCPU, 2GB RAM**: ~$15-20/month
- **Data transfer**: ~$5-10/month
- **Total**: ~$20-30/month

### EC2 (Monthly)
- **t3.micro**: ~$8-10/month
- **Data transfer**: ~$5-10/month
- **Total**: ~$13-20/month

## 🎯 **Next Steps**

1. **Choose deployment option** (App Runner recommended)
2. **Set up AWS infrastructure**
3. **Deploy application**
4. **Test thoroughly**
5. **Update frontend endpoints**
6. **Go live!**

## 📞 **Support**

- **Backup location**: `backend-backup-YYYYMMDD-HHMMSS/`
- **Restore script**: `restore.sh`
- **Test scripts**: Multiple `.sh` files for verification
- **Documentation**: This checklist and deployment scripts
