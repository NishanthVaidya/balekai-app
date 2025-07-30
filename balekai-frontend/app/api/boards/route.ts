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
    
    const board = await prisma.board.create({
      data: {
        name,
        isPrivate: isPrivate || false,
        visibility: visibility || 'PUBLIC',
        ownerId,
        ownerName,
      },
    });
    
    return NextResponse.json(board, { status: 201 });
  } catch (error) {
    console.error('Error creating board:', error);
    return NextResponse.json(
      { error: 'Failed to create board' },
      { status: 500 }
    );
  }
} 