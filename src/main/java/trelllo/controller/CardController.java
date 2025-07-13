package trelllo.controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import trelllo.model.Card;
import trelllo.model.TrelloList;
import trelllo.model.User;
import trelllo.repository.CardRepository;
import trelllo.repository.TrelloListRepository;
import trelllo.repository.UserRepository;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/cards")
@RequiredArgsConstructor
public class CardController {

    private final CardRepository cardRepository;
    private final TrelloListRepository trelloListRepository;
    private final UserRepository userRepository;

    // 🆕 Create Card only in "To Do" lists
    @PostMapping
    public ResponseEntity<?> createCard(@RequestBody Card card) {
        if (card.getList() == null || card.getList().getId() == null) {
            return ResponseEntity.badRequest().body("List is required to create a card.");
        }

        TrelloList list = trelloListRepository.findById(card.getList().getId())
                .orElseThrow(() -> new RuntimeException("List not found with id: " + card.getList().getId()));

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
    public ResponseEntity<Card> getCardById(@PathVariable Long id) {
        Card card = cardRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Card not found with id: " + id));
        return ResponseEntity.ok(card);
    }

    // 🆕 Get All Cards
    @GetMapping
    public List<Card> getAllCards() {
        return cardRepository.findAll();
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
        Card card = cardRepository.findById(cardId)
                .orElseThrow(() -> new RuntimeException("Card not found with id: " + cardId));

        String previousState = card.getCurrentState();
        card.setCurrentState(newState);

        if (card.getStateHistory() == null) {
            card.setStateHistory(new ArrayList<>());
        }
        card.getStateHistory().add(
                (previousState == null ? "Created" : previousState) + " → " + newState + " at " + LocalDateTime.now()
        );

        cardRepository.save(card);
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
    public ResponseEntity<String> assignCardToUser(
            @PathVariable Long cardId,
            @RequestParam Long userId
    ) {
        Card card = cardRepository.findById(cardId)
                .orElseThrow(() -> new RuntimeException("Card not found with id: " + cardId));

        User previousUser = card.getAssignedUser();

        User newUser = userRepository.findById(String.valueOf(userId))
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
    public ResponseEntity<List<String>> getCardHistory(@PathVariable Long cardId) {
        Card card = cardRepository.findById(cardId)
                .orElseThrow(() -> new RuntimeException("Card not found with id: " + cardId));

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
