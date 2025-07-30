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

export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ cardId: string }> }
) {
  try {
    const { cardId } = await params;
    const cardIdNum = parseInt(cardId);
    const card = cardsData.cards.find(c => c.id === cardIdNum);
    
    if (!card) {
      return NextResponse.json(
        { error: 'Card not found' },
        { status: 404 }
      );
    }

    const body = await request.json();
    
    // Update card properties
    if (body.title !== undefined) card.title = body.title;
    if (body.label !== undefined) card.label = body.label;
    if (body.currentState !== undefined) card.currentState = body.currentState;
    if (body.listId !== undefined) card.listId = body.listId;
    if (body.assignedUser !== undefined) card.assignedUser = body.assignedUser;

    return NextResponse.json(card);
  } catch (error) {
    console.error('Error updating card:', error);
    return NextResponse.json(
      { error: 'Failed to update card' },
      { status: 500 }
    );
  }
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ cardId: string }> }
) {
  try {
    const { cardId } = await params;
    const cardIdNum = parseInt(cardId);
    const cardIndex = cardsData.cards.findIndex(c => c.id === cardIdNum);
    
    if (cardIndex === -1) {
      return NextResponse.json(
        { error: 'Card not found' },
        { status: 404 }
      );
    }

    // Remove the card
    cardsData.cards.splice(cardIndex, 1);

    return NextResponse.json({ message: 'Card deleted successfully' });
  } catch (error) {
    console.error('Error deleting card:', error);
    return NextResponse.json(
      { error: 'Failed to delete card' },
      { status: 500 }
    );
  }
} 