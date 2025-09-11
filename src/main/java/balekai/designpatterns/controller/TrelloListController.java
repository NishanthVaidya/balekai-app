package balekai.designpatterns.controller;

import balekai.designpatterns.model.TrelloList;
import balekai.designpatterns.model.Board;
import balekai.designpatterns.model.User;
import balekai.designpatterns.repository.TrelloListRepository;
import balekai.designpatterns.repository.BoardRepository;
import balekai.designpatterns.repository.UserRepository;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Profile;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/lists")
@Profile("!test") // Don't load this controller in test profile
public class TrelloListController {

    @Autowired
    private TrelloListRepository trelloListRepository;

    @Autowired
    private BoardRepository boardRepository;

    @Autowired
    private UserRepository userRepository;

    @PostMapping("/{boardId}")
    public ResponseEntity<?> createList(@PathVariable Long boardId, @RequestBody TrelloList list, HttpServletRequest request) {
        // Get authenticated user
        String userEmail = (String) request.getAttribute("authenticatedUserEmail");
        if (userEmail == null) {
            return ResponseEntity.status(401).body("Unauthorized");
        }

        User authenticatedUser = userRepository.findByEmail(userEmail).orElse(null);
        if (authenticatedUser == null) {
            return ResponseEntity.status(401).body("User not found");
        }

        // Check if user has access to the board
        Board board = boardRepository.findById(boardId)
                .orElseThrow(() -> new RuntimeException("Board not found"));
        
        if (board.isAPrivate() && !board.getOwnerId().equals(authenticatedUser.getId())) {
            return ResponseEntity.status(403).body("Access denied: Cannot create lists in private boards you don't own");
        }

        list.setBoard(board);
        TrelloList savedList = trelloListRepository.save(list);
        return ResponseEntity.ok(savedList);
    }
    
    @PostMapping
    public ResponseEntity<?> createList(@RequestBody TrelloList list, HttpServletRequest request) {
        // Get authenticated user
        String userEmail = (String) request.getAttribute("authenticatedUserEmail");
        if (userEmail == null) {
            return ResponseEntity.status(401).body("Unauthorized");
        }

        User authenticatedUser = userRepository.findByEmail(userEmail).orElse(null);
        if (authenticatedUser == null) {
            return ResponseEntity.status(401).body("User not found");
        }

        // If list has a board, check access
        if (list.getBoard() != null && list.getBoard().getId() != null) {
            Board board = boardRepository.findById(list.getBoard().getId())
                    .orElseThrow(() -> new RuntimeException("Board not found"));
            
            if (board.isAPrivate() && !board.getOwnerId().equals(authenticatedUser.getId())) {
                return ResponseEntity.status(403).body("Access denied: Cannot create lists in private boards you don't own");
            }
        }

        TrelloList savedList = trelloListRepository.save(list);
        return ResponseEntity.ok(savedList);
    }

    @GetMapping
    @Transactional(readOnly = true)
    public ResponseEntity<?> getAllLists(HttpServletRequest request) {
        // Get authenticated user
        String userEmail = (String) request.getAttribute("authenticatedUserEmail");
        if (userEmail == null) {
            return ResponseEntity.status(401).body("Unauthorized");
        }

        User authenticatedUser = userRepository.findByEmail(userEmail).orElse(null);
        if (authenticatedUser == null) {
            return ResponseEntity.status(401).body("User not found");
        }

        List<TrelloList> lists = trelloListRepository.findAll();
        
        // Filter lists based on user access (only show lists from public boards or user's own private boards)
        List<TrelloList> accessibleLists = lists.stream()
            .filter(list -> {
                if (list.getBoard() != null) {
                    Board board = list.getBoard();
                    // Show lists from public boards or private boards owned by the user
                    return !board.isAPrivate() || board.getOwnerId().equals(authenticatedUser.getId());
                }
                return true; // Show lists without board association
            })
            .toList();
        
        // Initialize lazy collections to avoid Hibernate lazy loading issues
        accessibleLists.forEach(list -> {
            if (list.getCards() != null) {
                list.getCards().size(); // Force initialization
                // Initialize card properties
                list.getCards().forEach(card -> {
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
            }
        });
        
        return ResponseEntity.ok(accessibleLists);
    }

    @GetMapping("/{id}")
    @Transactional(readOnly = true)
    public ResponseEntity<?> getList(@PathVariable Long id, HttpServletRequest request) {
        // Get authenticated user
        String userEmail = (String) request.getAttribute("authenticatedUserEmail");
        if (userEmail == null) {
            return ResponseEntity.status(401).body("Unauthorized");
        }

        User authenticatedUser = userRepository.findByEmail(userEmail).orElse(null);
        if (authenticatedUser == null) {
            return ResponseEntity.status(401).body("User not found");
        }

        TrelloList list = trelloListRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("List not found"));
        
        // Check if user has access to this list's board
        if (list.getBoard() != null) {
            Board board = list.getBoard();
            if (board.isAPrivate() && !board.getOwnerId().equals(authenticatedUser.getId())) {
                return ResponseEntity.status(403).body("Access denied: Cannot access lists in private boards you don't own");
            }
        }
        
        // Initialize lazy collections to avoid Hibernate lazy loading issues
        if (list.getCards() != null) {
            list.getCards().size(); // Force initialization
            // Initialize card properties
            list.getCards().forEach(card -> {
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
        }
        
        return ResponseEntity.ok(list);
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateList(@PathVariable Long id, @RequestBody TrelloList list, HttpServletRequest request) {
        // Get authenticated user
        String userEmail = (String) request.getAttribute("authenticatedUserEmail");
        if (userEmail == null) {
            return ResponseEntity.status(401).body("Unauthorized");
        }

        User authenticatedUser = userRepository.findByEmail(userEmail).orElse(null);
        if (authenticatedUser == null) {
            return ResponseEntity.status(401).body("User not found");
        }

        TrelloList existingList = trelloListRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("List not found"));
        
        // Check if user has access to update this list's board
        if (existingList.getBoard() != null) {
            Board board = existingList.getBoard();
            if (board.isAPrivate() && !board.getOwnerId().equals(authenticatedUser.getId())) {
                return ResponseEntity.status(403).body("Access denied: Cannot update lists in private boards you don't own");
            }
        }
        
        existingList.setName(list.getName());
        TrelloList updatedList = trelloListRepository.save(existingList);
        return ResponseEntity.ok(updatedList);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteList(@PathVariable Long id, HttpServletRequest request) {
        // Get authenticated user
        String userEmail = (String) request.getAttribute("authenticatedUserEmail");
        if (userEmail == null) {
            return ResponseEntity.status(401).body("Unauthorized");
        }

        User authenticatedUser = userRepository.findByEmail(userEmail).orElse(null);
        if (authenticatedUser == null) {
            return ResponseEntity.status(401).body("User not found");
        }

        TrelloList list = trelloListRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("List not found"));
        
        // Check if user has access to delete this list's board
        if (list.getBoard() != null) {
            Board board = list.getBoard();
            if (board.isAPrivate() && !board.getOwnerId().equals(authenticatedUser.getId())) {
                return ResponseEntity.status(403).body("Access denied: Cannot delete lists in private boards you don't own");
            }
        }
        
        trelloListRepository.deleteById(id);
        return ResponseEntity.ok("List deleted successfully");
    }
}
