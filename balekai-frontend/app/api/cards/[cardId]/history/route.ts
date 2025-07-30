import { NextRequest, NextResponse } from 'next/server';

// Simple in-memory storage for card history
const cardHistoryData = {
  history: {
    1: [
      'Card created at 2024-01-15 10:30:00',
      'Assigned to John at 2024-01-15 11:00:00',
      'Moved to In Progress at 2024-01-16 09:15:00',
      'Moved back to To Do at 2024-01-16 14:20:00'
    ],
    2: [
      'Card created at 2024-01-15 10:35:00',
      'Assigned to Paul at 2024-01-15 11:30:00',
      'Label changed to Documentation at 2024-01-15 15:45:00'
    ],
    3: [
      'Card created at 2024-01-15 10:40:00',
      'Assigned to George at 2024-01-15 12:00:00',
      'Moved to In Progress at 2024-01-16 08:30:00',
      'Label changed to Feature at 2024-01-16 10:15:00'
    ],
    4: [
      'Card created at 2024-01-15 10:25:00',
      'Assigned to John at 2024-01-15 10:30:00',
      'Moved to Done at 2024-01-15 16:00:00'
    ]
  } as Record<number, string[]>
};

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ cardId: string }> }
) {
  try {
    const { cardId } = await params;
    const cardIdNum = parseInt(cardId);
    const history = cardHistoryData.history[cardIdNum] || [];
    
    return NextResponse.json(history);
  } catch (error) {
    console.error('Error fetching card history:', error);
    return NextResponse.json(
      { error: 'Failed to fetch card history' },
      { status: 500 }
    );
  }
} 