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

import org.springframework.http.ResponseEntity;
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

    // ✅ AUTHENTICATED USER'S OWN BOARDS ONLY
    @GetMapping("/me")
    public ResponseEntity<?> getMyBoards(HttpServletRequest request) {
        String uid = (String) request.getAttribute("firebaseUid");
        if (uid == null) {
            return ResponseEntity.status(401).body("Unauthorized");
        }

        List<Board> boards = boardRepository.findByOwnerId(uid);
        return ResponseEntity.ok(boards);
    }

    // ✅ ACCESSIBLE TO ALL - Public boards + own private boards
    @GetMapping
    public ResponseEntity<?> getAccessibleBoards(HttpServletRequest request) {
        String uid = (String) request.getAttribute("firebaseUid");

        List<Board> allBoards = boardRepository.findAll();

        List<Board> accessibleBoards = allBoards.stream()
                .filter(board -> !board.isAPrivate() || (uid != null && uid.equals(board.getOwnerId())))
                .toList();

        return ResponseEntity.ok(accessibleBoards);
    }


    // ✅ CREATE BOARD
    @PostMapping
    public ResponseEntity<Board> createBoard(@RequestBody BoardRequest boardRequest) {
        Board board;

        if (boardRequest.isAPrivate()) {
            board = privateBoardFactory.createBoard(boardRequest.getName(), boardRequest.getOwnerId());
        } else {
            board = standardBoardFactory.createBoard(boardRequest.getName(), boardRequest.getOwnerId());
        }

        board.setAPrivate(boardRequest.isAPrivate());
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
    public Board getBoard(@PathVariable Long id) {
        return boardRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Board not found"));
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
