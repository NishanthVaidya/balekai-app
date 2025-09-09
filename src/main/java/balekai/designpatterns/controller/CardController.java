package balekai.designpatterns.controller;

import balekai.designpatterns.model.Card;
import balekai.designpatterns.model.TrelloList;
import balekai.designpatterns.model.User;
import balekai.designpatterns.model.Board;
import balekai.designpatterns.repository.CardRepository;
import balekai.designpatterns.repository.TrelloListRepository;
import balekai.designpatterns.repository.UserRepository;
import balekai.designpatterns.service.CardService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Profile;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/cards")
@RequiredArgsConstructor
@Profile("!test") // Don't load this controller in test profile
public class CardController {

    private final CardRepository cardRepository;
    private final TrelloListRepository trelloListRepository;
    private final UserRepository userRepository;
    private final CardService cardService;

    // 🆕 Create Card only in "To Do" lists
    @PostMapping
    public ResponseEntity<?> createCard(@RequestBody Card card, HttpServletRequest request) {
        // Get authenticated user
        String userEmail = (String) request.getAttribute("authenticatedUserEmail");
        if (userEmail == null) {
            return ResponseEntity.status(401).body("Unauthorized");
        }

        User authenticatedUser = userRepository.findByEmail(userEmail).orElse(null);
        if (authenticatedUser == null) {
            return ResponseEntity.status(401).body("User not found");
        }

        if (card.getList() == null || card.getList().getId() == null) {
            return ResponseEntity.badRequest().body("List is required to create a card.");
        }

        TrelloList list = trelloListRepository.findById(card.getList().getId())
                .orElseThrow(() -> new RuntimeException("List not found with id: " + card.getList().getId()));

        // Check if user has access to this board
        Board board = list.getBoard();
        if (board != null && board.isAPrivate() && !board.getOwnerId().equals(authenticatedUser.getId())) {
            return ResponseEntity.status(403).body("Access denied: Cannot create cards in private boards you don't own");
        }

        if (!"To Do".equalsIgnoreCase(list.getName())) {
            return ResponseEntity.badRequest().body("Cards can only be created in the 'To Do' list.");
        }

        card.setCreatedAt(LocalDateTime.now());
        card.setCurrentState("To Do");
        card.setList(list);
        if (card.getStateHistory() == null) card.setStateHistory(new ArrayList<>());
        card.getStateHistory().add("Created in To Do at " + LocalDateTime.now());

        Card savedCard = cardRepository.save(card);
        return ResponseEntity.ok(savedCard);
    }

    // 🆕 Get Card by ID
    @GetMapping("/{id}")
    @Transactional(readOnly = true)
    public ResponseEntity<Card> getCardById(@PathVariable Long id, HttpServletRequest request) {
        // Get authenticated user
        String userEmail = (String) request.getAttribute("authenticatedUserEmail");
        if (userEmail == null) {
            return ResponseEntity.status(401).build();
        }

        User authenticatedUser = userRepository.findByEmail(userEmail).orElse(null);
        if (authenticatedUser == null) {
            return ResponseEntity.status(401).build();
        }

        Card card = cardRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Card not found with id: " + id));

        // Check if user has access to this card's board
        TrelloList list = card.getList();
        if (list != null && list.getBoard() != null) {
            Board board = list.getBoard();
            if (board.isAPrivate() && !board.getOwnerId().equals(authenticatedUser.getId())) {
                return ResponseEntity.status(403).build();
            }
        }
        
        // Initialize lazy collections to avoid Hibernate lazy loading issues
        if (card.getAssignedUser() != null) {
            card.getAssignedUser().getName(); // Force initialization
        }
        if (card.getComments() != null) {
            card.getComments().size(); // Force initialization
        }
        if (card.getStateHistory() != null) {
            card.getStateHistory().size(); // Force initialization
        }
        
        return ResponseEntity.ok(card);
    }

    // 🆕 Get All Cards
    @GetMapping
    @Transactional(readOnly = true)
    public List<Card> getAllCards() {
        List<Card> cards = cardRepository.findAll();
        
        // Initialize lazy collections to avoid Hibernate lazy loading issues
        cards.forEach(card -> {
            if (card.getAssignedUser() != null) {
                card.getAssignedUser().getName(); // Force initialization
            }
            if (card.getComments() != null) {
                card.getComments().size(); // Force initialization
            }
            if (card.getStateHistory() != null) {
                card.getStateHistory().size(); // Force initialization
            }
        });
        
        return cards;
    }

    // 🆕 Delete Card by ID
    @DeleteMapping("/{id}")
    public ResponseEntity<String> deleteCard(@PathVariable Long id) {
        Card card = cardRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Card not found with id: " + id));
        cardRepository.delete(card);
        return ResponseEntity.ok("Card deleted successfully!");
    }

    // ✅ Transition Card State
    @PutMapping("/{cardId}/transition")
    public ResponseEntity<String> transitionCardState(
            @PathVariable Long cardId,
            @RequestParam String newState
    ) {
        cardService.transitionCardState(cardId, newState);
        return ResponseEntity.ok("Card state updated successfully!");
    }

    // ✅ Move Card to Another List
    @PutMapping("/{cardId}/move")
    public ResponseEntity<String> moveCardToList(
            @PathVariable Long cardId,
            @RequestParam Long listId
    ) {
        Card card = cardRepository.findById(cardId)
                .orElseThrow(() -> new RuntimeException("Card not found with id: " + cardId));

        TrelloList newList = trelloListRepository.findById(listId)
                .orElseThrow(() -> new RuntimeException("List not found with id: " + listId));

        card.setList(newList);
        cardRepository.save(card);

        return ResponseEntity.ok("Card moved successfully!");
    }

    // ✅ Assign or Reassign a Card to a User with history
    @PutMapping("/{cardId}/assign")
    @Transactional
    public ResponseEntity<String> assignCardToUser(
            @PathVariable Long cardId,
            @RequestParam(required = false) String userId,
            HttpServletRequest request
    ) {
        // Get authenticated user
        String userEmail = (String) request.getAttribute("authenticatedUserEmail");
        if (userEmail == null) {
            return ResponseEntity.status(401).body("Unauthorized");
        }

        User authenticatedUser = userRepository.findByEmail(userEmail).orElse(null);
        if (authenticatedUser == null) {
            return ResponseEntity.status(401).body("User not found");
        }

        Card card = cardRepository.findById(cardId)
                .orElseThrow(() -> new RuntimeException("Card not found with id: " + cardId));

        // Check if the card belongs to a private board
        TrelloList list = card.getList();
        if (list != null && list.getBoard() != null) {
            Board board = list.getBoard();
            if (board.isAPrivate()) {
                // For private boards, only the owner can assign cards, and only to themselves
                if (!board.getOwnerId().equals(authenticatedUser.getId())) {
                    return ResponseEntity.status(403).body("Access denied: Only the board owner can assign cards in private boards");
                }
                
                // In private boards, cards can only be assigned to the board owner
                if (userId != null && !userId.trim().isEmpty() && !userId.equals(authenticatedUser.getId())) {
                    return ResponseEntity.status(403).body("Access denied: Cards in private boards can only be assigned to the board owner");
                }
            }
        }

        // Force initialization of lazy collections to prevent Hibernate lazy loading issues
        if (card.getStateHistory() != null) {
            card.getStateHistory().size(); // Force initialization
        }
        if (card.getComments() != null) {
            card.getComments().size(); // Force initialization
        }
        if (card.getAssignedUser() != null) {
            card.getAssignedUser().getName(); // Force initialization
        }

        User previousUser = card.getAssignedUser();

        if (userId == null || userId.trim().isEmpty()) {
            // Unassign the user
            card.setAssignedUser(null);
            
            if (card.getStateHistory() == null) {
                card.setStateHistory(new ArrayList<>());
            }
            
            String log = previousUser != null ? 
                "Unassigned from " + previousUser.getName() + " at " + LocalDateTime.now() :
                "Card remains unassigned at " + LocalDateTime.now();
            
            card.getStateHistory().add(log);
            cardRepository.save(card);
            return ResponseEntity.ok("User unassigned successfully.");
        }

        // Assign to a specific user
        User newUser = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found with id: " + userId));

        card.setAssignedUser(newUser);

        if (card.getStateHistory() == null) {
            card.setStateHistory(new ArrayList<>());
        }

        String log;
        if (previousUser == null) {
            log = "Assigned to " + newUser.getName() + " at " + LocalDateTime.now();
        } else {
            log = "Reassigned from " + previousUser.getName() + " to " + newUser.getName() + " at " + LocalDateTime.now();
        }

        card.getStateHistory().add(log);
        cardRepository.save(card);

        return ResponseEntity.ok("User assignment updated.");
    }

    // ✅ View Card Logs/History
    @GetMapping("/{cardId}/history")
    @Transactional(readOnly = true)
    public ResponseEntity<List<String>> getCardHistory(@PathVariable Long cardId) {
        Card card = cardRepository.findById(cardId)
                .orElseThrow(() -> new RuntimeException("Card not found with id: " + cardId));

        // Force initialization of lazy collections to prevent Hibernate lazy loading issues
        if (card.getStateHistory() != null) {
            card.getStateHistory().size(); // Force initialization
        }

        return ResponseEntity.ok(card.getStateHistory());
    }
    @PutMapping("/{cardId}/update-metadata")
    public ResponseEntity<Card> updateCardMetadata(
            @PathVariable Long cardId,
            @RequestBody Map<String, String> updates
    ) {
        Card card = cardRepository.findById(cardId)
                .orElseThrow(() -> new RuntimeException("Card not found"));

        if (updates.containsKey("title")) {
            card.setTitle(updates.get("title"));
        }
        if (updates.containsKey("label")) {
            card.setLabel(updates.get("label"));
        }

        cardRepository.save(card);
        return ResponseEntity.ok(card);
    }

}
