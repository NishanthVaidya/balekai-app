package balekai.designpatterns.controller;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Profile;
import org.springframework.web.bind.annotation.*;
import balekai.designpatterns.model.Board;
import balekai.designpatterns.model.TrelloList;
import balekai.designpatterns.repository.BoardRepository;
import balekai.designpatterns.repository.TrelloListRepository;
import balekai.designpatterns.request.BoardRequest;
import balekai.designpatterns.factory.StandardBoardFactory;
import balekai.designpatterns.factory.PrivateBoardFactory;
import balekai.designpatterns.repository.UserRepository;
import balekai.designpatterns.model.User;

import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import lombok.extern.slf4j.Slf4j;
import java.util.List;

@RestController
@RequestMapping("/boards")
@Profile("!test") // Don't load this controller in test profile
@Slf4j
public class BoardController {

    @Autowired
    private BoardRepository boardRepository;

    @Autowired
    private TrelloListRepository trelloListRepository;

    @Autowired
    private StandardBoardFactory standardBoardFactory;

    @Autowired
    private PrivateBoardFactory privateBoardFactory;

    @Autowired
    private UserRepository userRepository;

    // ✅ AUTHENTICATED USER'S OWN BOARDS ONLY
    @GetMapping("/me")
    @Transactional(readOnly = true)
    public ResponseEntity<?> getMyBoards(HttpServletRequest request) {
        String userEmail = (String) request.getAttribute("authenticatedUserEmail");
        if (userEmail == null) {
            return ResponseEntity.status(401).body("Unauthorized");
        }

        // Find user by email to get their ID
        User user = userRepository.findByEmail(userEmail).orElse(null);
        if (user == null) {
            return ResponseEntity.status(401).body("User not found");
        }

        List<Board> boards = boardRepository.findByOwnerId(user.getId());
        
        // Initialize lazy collections to avoid Hibernate lazy loading issues
        boards.forEach(board -> {
            if (board.getLists() != null) {
                board.getLists().size(); // Force initialization
                // Also initialize cards within each list
                board.getLists().forEach(list -> {
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
            }
        });
        
        return ResponseEntity.ok(boards);
    }

    // ✅ ACCESSIBLE TO ALL - Public boards + own private boards
    @GetMapping
    @Transactional(readOnly = true)
    public ResponseEntity<?> getAccessibleBoards(HttpServletRequest request) {
        String userEmail = (String) request.getAttribute("authenticatedUserEmail");
        final String uid;
        
        if (userEmail != null) {
            User user = userRepository.findByEmail(userEmail).orElse(null);
            if (user != null) {
                uid = user.getId();
            } else {
                uid = null;
            }
        } else {
            uid = null;
        }

        List<Board> allBoards = boardRepository.findAll();

        // Initialize lazy collections to avoid Hibernate lazy loading issues
        allBoards.forEach(board -> {
            if (board.getLists() != null) {
                board.getLists().size(); // Force initialization
                // Also initialize cards within each list
                board.getLists().forEach(list -> {
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
            }
        });

        // ✅ Show ONLY boards created/owned by the authenticated user
        List<Board> accessibleBoards = allBoards.stream()
                .filter(board -> uid != null && uid.equals(board.getOwnerId()))
                .toList();

        log.info("Owner filtering: Found {} boards owned by user {}", accessibleBoards.size(), uid);
        return ResponseEntity.ok(accessibleBoards);
    }


    // ✅ CREATE BOARD
    @PostMapping
    public ResponseEntity<Board> createBoard(@RequestBody BoardRequest boardRequest, HttpServletRequest request) {
        // Get the authenticated user's ID from JWT authentication
        String userEmail = (String) request.getAttribute("authenticatedUserEmail");
        if (userEmail == null) {
            return ResponseEntity.status(401).build();
        }

        User user = userRepository.findByEmail(userEmail).orElse(null);
        if (user == null) {
            return ResponseEntity.status(401).build();
        }
        String authenticatedUserId = user.getId();
        if (authenticatedUserId == null) {
            return ResponseEntity.status(401).body(null);
        }

        // Use the authenticated user's ID instead of the client-provided ownerId
        // ✅ Always create private boards
        Board board = privateBoardFactory.createBoard(boardRequest.getName(), authenticatedUserId);
        board.setAPrivate(true); // ✅ Force all boards to be private
        board.setOwnerName(boardRequest.getOwnerName());

        Board savedBoard = boardRepository.save(board);

        List<String> defaultLists = List.of("To Do", "In Progress", "Blocked", "Review", "Done");
        for (String listName : defaultLists) {
            TrelloList list = new TrelloList();
            list.setName(listName);
            list.setBoard(savedBoard);
            trelloListRepository.save(list);
        }

        return ResponseEntity.ok(savedBoard);
    }

    // ✅ GET BOARD BY ID
    @GetMapping("/{id}")
    @Transactional(readOnly = true)
    public ResponseEntity<?> getBoard(@PathVariable Long id, HttpServletRequest request) {
        // Get authenticated user
        String userEmail = (String) request.getAttribute("authenticatedUserEmail");
        if (userEmail == null) {
            return ResponseEntity.status(401).body("Unauthorized");
        }

        User authenticatedUser = userRepository.findByEmail(userEmail).orElse(null);
        if (authenticatedUser == null) {
            return ResponseEntity.status(401).body("User not found");
        }

        Board board = boardRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Board not found"));
        
        // Check if user has access to this board
        if (board.isAPrivate() && !board.getOwnerId().equals(authenticatedUser.getId())) {
            return ResponseEntity.status(403).body("Access denied: Cannot access private boards you don't own");
        }
        
        // Initialize lazy collections to avoid Hibernate lazy loading issues
        if (board.getLists() != null) {
            board.getLists().size(); // Force initialization
            // Also initialize cards within each list
            board.getLists().forEach(list -> {
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
        }
        
        return ResponseEntity.ok(board);
    }

    // ✅ UPDATE BOARD
    @PutMapping("/{id}")
    public ResponseEntity<?> updateBoard(@PathVariable Long id, @RequestBody Board board, HttpServletRequest request) {
        // Get authenticated user
        String userEmail = (String) request.getAttribute("authenticatedUserEmail");
        if (userEmail == null) {
            return ResponseEntity.status(401).body("Unauthorized");
        }

        User authenticatedUser = userRepository.findByEmail(userEmail).orElse(null);
        if (authenticatedUser == null) {
            return ResponseEntity.status(401).body("User not found");
        }

        Board existingBoard = boardRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Board not found"));
        
        // Check if user has access to update this board
        if (existingBoard.isAPrivate() && !existingBoard.getOwnerId().equals(authenticatedUser.getId())) {
            return ResponseEntity.status(403).body("Access denied: Cannot update private boards you don't own");
        }
        
        existingBoard.setName(board.getName());
        // Don't allow changing ownerId - keep the original owner
        existingBoard.setOwnerName(board.getOwnerName());
        Board updatedBoard = boardRepository.save(existingBoard);
        return ResponseEntity.ok(updatedBoard);
    }

    // ✅ DELETE BOARD
    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteBoard(@PathVariable Long id, HttpServletRequest request) {
        // Get authenticated user
        String userEmail = (String) request.getAttribute("authenticatedUserEmail");
        if (userEmail == null) {
            return ResponseEntity.status(401).body("Unauthorized");
        }

        User authenticatedUser = userRepository.findByEmail(userEmail).orElse(null);
        if (authenticatedUser == null) {
            return ResponseEntity.status(401).body("User not found");
        }

        Board board = boardRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Board not found"));
        
        // Check if user has access to delete this board
        if (board.isAPrivate() && !board.getOwnerId().equals(authenticatedUser.getId())) {
            return ResponseEntity.status(403).body("Access denied: Cannot delete private boards you don't own");
        }
        
        boardRepository.deleteById(id);
        return ResponseEntity.ok("Board deleted successfully");
    }


}