package trelllo.designpatterns.factory;

import org.springframework.stereotype.Component;
import trelllo.model.Board;

@Component
public class StandardBoardFactory {
    public Board createBoard(String name, String ownerId) {
        Board board = new Board();
        board.setName(name);
        board.setOwnerId(ownerId);
        //board.setPrivate(false); // ✅ Explicitly mark it as public
        return board;
    }
}
