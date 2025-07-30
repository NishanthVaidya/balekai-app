import { NextRequest, NextResponse } from 'next/server';

// Simple in-memory storage for now (we'll replace with Prisma later)
const users = [
  { id: '1', name: 'John', email: 'john@example.com' },
  { id: '2', name: 'Paul', email: 'paul@example.com' },
  { id: '3', name: 'George', email: 'george@example.com' },
  { id: '4', name: 'Ringo', email: 'ringo@example.com' },
];

export async function GET() {
  try {
    return NextResponse.json(users);
  } catch (error) {
    console.error('Error fetching users:', error);
    return NextResponse.json(
      { error: 'Failed to fetch users' },
      { status: 500 }
    );
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { name, email } = body;
    
    const newUser = {
      id: (users.length + 1).toString(),
      name,
      email,
    };
    
    // Note: In a real app, you'd add to a mutable array or database
    // For now, we'll just return the user without storing it
    
    return NextResponse.json(newUser, { status: 201 });
  } catch (error) {
    console.error('Error creating user:', error);
    return NextResponse.json(
      { error: 'Failed to create user' },
      { status: 500 }
    );
  }
} 