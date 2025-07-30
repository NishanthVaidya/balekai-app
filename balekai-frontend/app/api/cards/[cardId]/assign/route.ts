import { NextRequest, NextResponse } from 'next/server';

// Simple in-memory storage for cards (shared with main cards route)
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
  }>
};

// Simple in-memory storage for users
const usersData = {
  users: [
    { id: 1, name: 'John' },
    { id: 2, name: 'Paul' },
    { id: 3, name: 'George' },
    { id: 4, name: 'Ringo' }
  ]
};

export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ cardId: string }> }
) {
  try {
    const { cardId } = await params;
    const cardIdNum = parseInt(cardId);
    const { searchParams } = new URL(request.url);
    const userId = searchParams.get('userId');
    
    if (!userId) {
      return NextResponse.json(
        { error: 'User ID is required' },
        { status: 400 }
      );
    }

    const card = cardsData.cards.find(c => c.id === cardIdNum);
    if (!card) {
      return NextResponse.json(
        { error: 'Card not found' },
        { status: 404 }
      );
    }

    const user = usersData.users.find(u => u.id === parseInt(userId));
    if (!user) {
      return NextResponse.json(
        { error: 'User not found' },
        { status: 404 }
      );
    }

    // Assign the user to the card
    card.assignedUser = user;

    return NextResponse.json({ message: 'User assigned successfully' });
  } catch (error) {
    console.error('Error assigning user to card:', error);
    return NextResponse.json(
      { error: 'Failed to assign user to card' },
      { status: 500 }
    );
  }
} 