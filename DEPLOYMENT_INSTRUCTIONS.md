# 🚀 Balekai Vercel Deployment Instructions

## 🚨 **Current Issue**
Your Balekai application is getting a 404 error on Vercel because:
1. Vercel can't run Spring Boot applications
2. The repository structure needs to be optimized for Vercel deployment

## 📋 **Solution: Deploy Frontend Only to Vercel**

### **Step 1: Deploy Backend Separately**
First, deploy your Spring Boot backend to a platform that supports Java:

**Option A: Railway (Recommended)**
```bash
# Install Railway CLI
npm install -g @railway/cli

# Login to Railway
railway login

# Deploy backend
cd /path/to/your/backend
railway init
railway up
```

**Option B: Heroku**
```bash
# Create Procfile in root directory
echo "web: java -jar target/balekai-1.0-SNAPSHOT.jar" > Procfile

# Deploy to Heroku
heroku create balekai-backend
git push heroku main
```

### **Step 2: Update Frontend Configuration**
Update the API URL in your frontend to point to your deployed backend:

```bash
# In Vercel dashboard, add environment variable:
NEXT_PUBLIC_API_URL=https://your-backend-url.com
```

### **Step 3: Deploy Frontend to Vercel**
```bash
# Connect your GitHub repository to Vercel
# Vercel will automatically detect the Next.js app in balekai-frontend/
```

## 🔧 **Alternative: Full Vercel Deployment**

If you want to deploy everything on Vercel, you need to convert your backend to Next.js API routes:

### **Step 1: Install Prisma**
```bash
cd balekai-frontend
npm install @prisma/client prisma
npx prisma init
```

### **Step 2: Set up Database**
Use Vercel Postgres or external database (Supabase, PlanetScale)

### **Step 3: Convert Backend Logic**
Move your Spring Boot controllers to Next.js API routes in `balekai-frontend/app/api/`

## 🎯 **Recommended Approach**

**For Production**: Use hybrid deployment
- Frontend: Vercel
- Backend: Railway/Heroku
- Database: Vercel Postgres or external

**For Development**: Keep current setup
- Frontend: localhost:3001
- Backend: localhost:8080
- Database: local PostgreSQL

## 📞 **Need Help?**

1. **Backend Deployment**: Choose Railway (easier) or Heroku
2. **Database**: Use Vercel Postgres for simplicity
3. **Environment Variables**: Set in Vercel dashboard
4. **CORS**: Configure in your backend to allow Vercel domain 