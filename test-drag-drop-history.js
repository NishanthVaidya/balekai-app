#!/usr/bin/env node

/**
 * Test script to verify drag-and-drop state history tracking
 * This simulates the frontend drag-and-drop functionality
 */

const axios = require('axios');

const API_BASE_URL = 'http://balekai-alb-new-626347040.us-east-1.elb.amazonaws.com';

async function testDragDropHistory() {
    console.log('🧪 Testing Drag-and-Drop State History Tracking\n');
    
    try {
        // Get initial state of a card
        console.log('1. Getting initial card state...');
        const cardResponse = await axios.get(`${API_BASE_URL}/cards/9`);
        const card = cardResponse.data;
        
        console.log(`   Card ID: ${card.id}`);
        console.log(`   Title: ${card.title}`);
        console.log(`   Current State: ${card.currentState}`);
        console.log(`   Initial History Length: ${card.stateHistory.length}`);
        console.log(`   Last History Entry: ${card.stateHistory[card.stateHistory.length - 1]}\n`);
        
        // Simulate drag-and-drop: Move from current state to "Review"
        const targetState = 'Review';
        const targetListId = 4; // Review list ID
        
        console.log(`2. Simulating drag-and-drop: ${card.currentState} → ${targetState}`);
        
        // Step 1: Move card to target list
        console.log('   Moving card to target list...');
        await axios.put(`${API_BASE_URL}/cards/9/move?listId=${targetListId}`);
        
        // Step 2: Update card state
        console.log('   Updating card state...');
        await axios.put(`${API_BASE_URL}/cards/9/transition?newState=${targetState}`);
        
        // Get updated state
        console.log('3. Getting updated card state...');
        const updatedCardResponse = await axios.get(`${API_BASE_URL}/cards/9`);
        const updatedCard = updatedCardResponse.data;
        
        console.log(`   New Current State: ${updatedCard.currentState}`);
        console.log(`   Updated History Length: ${updatedCard.stateHistory.length}`);
        console.log(`   New History Entry: ${updatedCard.stateHistory[updatedCard.stateHistory.length - 1]}\n`);
        
        // Verify the state history was updated
        const historyIncreased = updatedCard.stateHistory.length > card.stateHistory.length;
        const lastEntryMatches = updatedCard.stateHistory[updatedCard.stateHistory.length - 1].includes(`${card.currentState} → ${targetState}`);
        
        console.log('4. Verification Results:');
        console.log(`   ✅ History length increased: ${historyIncreased}`);
        console.log(`   ✅ Last entry matches transition: ${lastEntryMatches}`);
        console.log(`   ✅ Current state updated: ${updatedCard.currentState === targetState}`);
        
        if (historyIncreased && lastEntryMatches && updatedCard.currentState === targetState) {
            console.log('\n🎉 SUCCESS: Drag-and-drop state history tracking is working correctly!');
            return true;
        } else {
            console.log('\n❌ FAILURE: Drag-and-drop state history tracking has issues.');
            return false;
        }
        
    } catch (error) {
        console.error('❌ Error during test:', error.message);
        if (error.response) {
            console.error('   Response status:', error.response.status);
            console.error('   Response data:', error.response.data);
        }
        return false;
    }
}

// Run the test
testDragDropHistory().then(success => {
    process.exit(success ? 0 : 1);
});
