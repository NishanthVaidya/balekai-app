# 🚀 Balekai Vercel Deployment Guide

## 📋 **Overview**

Your Balekai application has a **hybrid architecture** that requires special consideration for Vercel deployment:

- ✅ **Frontend**: Next.js (Perfect for Vercel)
- ❌ **Backend**: Spring Boot Java (Cannot run on Vercel)

## 🔧 **Deployment Options**

### **Option 1: Full Vercel Deployment (Recommended)**
Convert backend to Next.js API routes + External Database

### **Option 2: Hybrid Deployment**
- Frontend on Vercel
- Backend on separate platform

---

## 🎯 **Option 1: Full Vercel Deployment**

### **Step 1: Database Setup**

#### **A. Use Vercel Postgres (Recommended)**
```bash
# In your Vercel dashboard
1. Go to Storage tab
2. Create new Postgres database
3. Copy the connection string
```

#### **B. Or Use External Database**
- **Supabase** (Free tier available)
- **PlanetScale** (Free tier available)
- **Neon** (Free tier available)

### **Step 2: Convert Backend to Next.js API Routes**

#### **Install Dependencies**
```bash
cd balekai-frontend
npm install @prisma/client
npm install -D prisma
```

#### **Initialize Prisma**
```bash
npx prisma init
```

#### **Create Prisma Schema** (`prisma/schema.prisma`)
```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id       String @id @default(cuid())
  name     String
  email    String @unique
  password String
  
  boards   Board[]
  cards    Card[]
  
  @@map("user")
}

model Board {
  id          String @id @default(cuid())
  name        String
  isPrivate   Boolean @default(false)
  visibility  String @default("PUBLIC")
  ownerId     String
  ownerName   String
  
  owner       User         @relation(fields: [ownerId], references: [id])
  lists       TrelloList[]
  
  @@map("board")
}

model TrelloList {
  id      String @id @default(cuid())
  name    String
  boardId String
  
  board   Board  @relation(fields: [boardId], references: [id])
  cards   Card[]
  
  @@map("trello_list")
}

model Card {
  id              String    @id @default(cuid())
  title           String
  description     String?
  label           String?
  dueDate         DateTime?
  currentState    String    @default("TODO")
  createdAt       DateTime  @default(now())
  listId          String
  assignedUserId  String?
  
  list            TrelloList @relation(fields: [listId], references: [id])
  assignedUser    User?      @relation(fields: [assignedUserId], references: [id])
  
  @@map("card")
}
```

#### **Create API Routes**

**`app/api/users/route.ts`**
```typescript
import { NextRequest, NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export async function GET() {
  try {
    const users = await prisma.user.findMany({
      select: {
        id: true,
        name: true,
        email: true,
      },
    });
    
    return NextResponse.json(users);
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to fetch users' },
      { status: 500 }
    );
  }
}
```

**`app/api/boards/route.ts`**
```typescript
import { NextRequest, NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export async function GET() {
  try {
    const boards = await prisma.board.findMany({
      include: {
        lists: {
          include: {
            cards: {
              include: {
                assignedUser: {
                  select: {
                    id: true,
                    name: true,
                    email: true,
                  },
                },
              },
            },
          },
        },
      },
    });
    
    return NextResponse.json(boards);
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to fetch boards' },
      { status: 500 }
    );
  }
}
```

### **Step 3: Update Frontend API Calls**

**Update `lib/api.tsx`**
```typescript
// Replace Spring Boot endpoints with Next.js API routes
const API_BASE = process.env.NEXT_PUBLIC_API_URL || '';

export const api = {
  users: {
    getAll: () => fetch(`${API_BASE}/api/users`).then(res => res.json()),
    create: (data: any) => fetch(`${API_BASE}/api/users`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    }).then(res => res.json()),
  },
  boards: {
    getAll: () => fetch(`${API_BASE}/api/boards`).then(res => res.json()),
    create: (data: any) => fetch(`${API_BASE}/api/boards`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    }).then(res => res.json()),
  },
};
```

### **Step 4: Environment Variables**

**`.env.local`**
```env
DATABASE_URL="postgresql://username:password@host:port/database"
NEXTAUTH_SECRET="your-secret-key"
NEXTAUTH_URL="http://localhost:3000"
```

### **Step 5: Deploy to Vercel**

```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel

# Set environment variables in Vercel dashboard
```

---

## 🔄 **Option 2: Hybrid Deployment**

### **Frontend (Vercel)**
- Deploy only the `balekai-frontend` folder
- Update API calls to point to your backend URL

### **Backend (Separate Platform)**
Choose one of these platforms:

#### **A. Railway (Recommended)**
```bash
# Install Railway CLI
npm i -g @railway/cli

# Deploy Spring Boot app
railway login
railway init
railway up
```

#### **B. Heroku**
```bash
# Create Procfile
echo "web: java -jar target/balekai-1.0-SNAPSHOT.jar" > Procfile

# Deploy
heroku create balekai-app
git push heroku main
```

#### **C. Render**
- Connect your GitHub repository
- Set build command: `mvn clean package`
- Set start command: `java -jar target/balekai-1.0-SNAPSHOT.jar`

### **Database Setup**
- Use the same database for both frontend and backend
- Update connection strings accordingly

---

## ⚙️ **Required Changes Summary**

### **For Option 1 (Full Vercel):**
1. ✅ Convert Spring Boot controllers to Next.js API routes
2. ✅ Replace JPA with Prisma ORM
3. ✅ Update frontend API calls
4. ✅ Set up external database
5. ✅ Configure environment variables

### **For Option 2 (Hybrid):**
1. ✅ Deploy frontend to Vercel
2. ✅ Deploy backend to separate platform
3. ✅ Update frontend API base URL
4. ✅ Configure CORS on backend
5. ✅ Set up shared database

---

## 🎯 **Recommendation**

**Use Option 1 (Full Vercel)** because:
- ✅ Simpler deployment
- ✅ Better performance
- ✅ Lower costs
- ✅ Easier maintenance
- ✅ Better integration

**Estimated Time**: 4-6 hours for conversion
**Cost**: Free tier available on Vercel + Database

---

## 🚨 **Important Notes**

1. **Firebase Authentication**: Will work on both options
2. **File Uploads**: Use Vercel Blob or external storage
3. **Real-time Features**: Consider using WebSockets or Server-Sent Events
4. **Environment Variables**: Set in Vercel dashboard
5. **Database Migrations**: Run `npx prisma db push` after deployment

---

## 📞 **Need Help?**

If you need assistance with the conversion, I can help you:
1. Convert specific Spring Boot endpoints
2. Set up the database schema
3. Configure deployment settings
4. Troubleshoot any issues 