import { NextRequest, NextResponse } from 'next/server';

// Simple in-memory storage for now
const boardsData = {
  boards: [
    {
      id: '1',
      name: 'Project Planning',
      isPrivate: false,
      visibility: 'PUBLIC',
      ownerId: '1',
      ownerName: 'John',
      lists: [
        {
          id: 1,
          name: 'To Do',
          cards: [
            {
              id: 1,
              title: 'Set up project structure',
              currentState: 'To Do',
              label: 'Default',
              assignedUser: { id: 1, name: 'John' }
            },
            {
              id: 2,
              title: 'Create initial documentation',
              currentState: 'To Do',
              label: 'Documentation',
              assignedUser: { id: 2, name: 'Paul' }
            }
          ]
        },
        {
          id: 2,
          name: 'In Progress',
          cards: [
            {
              id: 3,
              title: 'Design user interface',
              currentState: 'In Progress',
              label: 'Feature',
              assignedUser: { id: 3, name: 'George' }
            }
          ]
        },
        {
          id: 3,
          name: 'Done',
          cards: [
            {
              id: 4,
              title: 'Project kickoff meeting',
              currentState: 'Done',
              label: 'Default',
              assignedUser: { id: 1, name: 'John' }
            }
          ]
        }
      ]
    }
  ]
};

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ boardId: string }> }
) {
  try {
    const { boardId } = await params;
    const board = boardsData.boards.find(b => b.id === boardId);
    
    if (!board) {
      return NextResponse.json(
        { error: 'Board not found' },
        { status: 404 }
      );
    }

    return NextResponse.json(board);
  } catch (error) {
    console.error('Error fetching board:', error);
    return NextResponse.json(
      { error: 'Failed to fetch board' },
      { status: 500 }
    );
  }
} 