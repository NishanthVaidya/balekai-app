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
import java.util.List;

@RestController
@RequestMapping("/boards")
@Profile("!test") // Don't load this controller in test profile
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

        List<Board> accessibleBoards = allBoards.stream()
                .filter(board -> !board.isAPrivate() || (uid != null && uid.equals(board.getOwnerId())))
                .toList();

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
    public Board getBoard(@PathVariable Long id) {
        Board board = boardRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Board not found"));
        
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
        
        return board;
    }

    // ✅ UPDATE BOARD
    @PutMapping("/{id}")
    public Board updateBoard(@PathVariable Long id, @RequestBody Board board) {
        Board existingBoard = boardRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Board not found"));
        existingBoard.setName(board.getName());
        existingBoard.setOwnerId(board.getOwnerId());
        existingBoard.setOwnerName(board.getOwnerName());
        return boardRepository.save(existingBoard);
    }

    // ✅ DELETE BOARD
    @DeleteMapping("/{id}")
    public void deleteBoard(@PathVariable Long id) {
        boardRepository.deleteById(id);
    }


}