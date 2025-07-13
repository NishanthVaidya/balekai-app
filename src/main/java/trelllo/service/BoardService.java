package trelllo.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import trelllo.model.Board;
import trelllo.repository.BoardRepository;
import trelllo.repository.UserRepository;
import trelllo.response.BoardResponse;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class BoardService {

    @Autowired
    private BoardRepository boardRepository;

    @Autowired
    private UserRepository userRepository;

    public List<BoardResponse> getAllBoards() {
        return boardRepository.findAll().stream().map(board -> {
            BoardResponse dto = new BoardResponse();
            dto.setId(board.getId());
            dto.setName(board.getName());
            dto.setVisibility(board.getVisibility());
            dto.setOwnerId(board.getOwnerId());



            // Fetch user and set user-specific info
            userRepository.findById(board.getOwnerId()).ifPresent(user -> {
                dto.setOwnerEmail(user.getEmail()); // keep this if needed
                dto.setOwnerFullName(user.getName());
            });


            return dto;
        }).collect(Collectors.toList());
    }

    public Board createBoard(Board board) {
        return boardRepository.save(board);
    }

    public Board getBoard(Long id) {
        return boardRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Board not found"));
    }



    public Board updateBoard(Long id, Board updatedBoard) {
        Board board = getBoard(id);
        board.setName(updatedBoard.getName());
        board.setOwnerId(updatedBoard.getOwnerId());
        return boardRepository.save(board);
    }

    public void deleteBoard(Long id) {
        boardRepository.deleteById(id);
    }
}
