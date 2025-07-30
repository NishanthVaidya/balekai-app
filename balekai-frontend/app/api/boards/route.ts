import { NextRequest, NextResponse } from 'next/server';

// Simple in-memory storage for now
let boards = [
  {
    id: '1',
    name: 'Project Planning',
    isPrivate: false,
    visibility: 'PUBLIC',
    ownerId: '1',
    ownerName: 'John',
    lists: []
  }
];

export async function GET() {
  try {
    return NextResponse.json(boards);
  } catch (error) {
    console.error('Error fetching boards:', error);
    return NextResponse.json(
      { error: 'Failed to fetch boards' },
      { status: 500 }
    );
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { name, isPrivate, visibility, ownerId, ownerName } = body;
    
    const newBoard = {
      id: (boards.length + 1).toString(),
      name,
      isPrivate: isPrivate || false,
      visibility: visibility || 'PUBLIC',
      ownerId,
      ownerName,
      lists: []
    };
    
    boards.push(newBoard);
    
    return NextResponse.json(newBoard, { status: 201 });
  } catch (error) {
    console.error('Error creating board:', error);
    return NextResponse.json(
      { error: 'Failed to create board' },
      { status: 500 }
    );
  }
} 