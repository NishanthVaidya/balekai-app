import { NextRequest, NextResponse } from 'next/server';

// Simple in-memory storage for cards
const cardsData = {
  cards: [
    {
      id: 1,
      title: 'Set up project structure',
      currentState: 'To Do',
      label: 'Default',
      listId: 1,
      assignedUser: { id: 1, name: 'John' }
    },
    {
      id: 2,
      title: 'Create initial documentation',
      currentState: 'To Do',
      label: 'Documentation',
      listId: 1,
      assignedUser: { id: 2, name: 'Paul' }
    },
    {
      id: 3,
      title: 'Design user interface',
      currentState: 'In Progress',
      label: 'Feature',
      listId: 2,
      assignedUser: { id: 3, name: 'George' }
    },
    {
      id: 4,
      title: 'Project kickoff meeting',
      currentState: 'Done',
      label: 'Default',
      listId: 3,
      assignedUser: { id: 1, name: 'John' }
    }
  ] as Array<{
    id: number;
    title: string;
    currentState: string;
    label: string;
    listId: number;
    assignedUser?: { id: number; name: string };
  }>,
  nextId: 5
};

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { title, label, currentState, list } = body;
    
    const newCard = {
      id: cardsData.nextId++,
      title,
      currentState: currentState || 'To Do',
      label: label || 'Default',
      listId: list?.id || 1,
      assignedUser: undefined
    };
    
    // Add the new card to the array
    cardsData.cards.push(newCard);
    
    return NextResponse.json(newCard, { status: 201 });
  } catch (error) {
    console.error('Error creating card:', error);
    return NextResponse.json(
      { error: 'Failed to create card' },
      { status: 500 }
    );
  }
} 