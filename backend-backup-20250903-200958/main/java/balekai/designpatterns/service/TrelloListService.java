package balekai.designpatterns.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Service;
import balekai.designpatterns.model.TrelloList;
import balekai.designpatterns.model.Board;
import balekai.designpatterns.repository.TrelloListRepository;
import balekai.designpatterns.repository.BoardRepository;

import java.util.List;

@Service
@Profile("!test") // Don't load this service in test profile
public class TrelloListService {

    @Autowired
    private TrelloListRepository listRepository;   // MISSING - Add this

    @Autowired
    private BoardRepository boardRepository;

    public TrelloList createList(Long boardId, TrelloList list) {
        Board board = boardRepository.findById(boardId)
                .orElseThrow(() -> new RuntimeException("Board not found"));

        list.setBoard(board);
        return listRepository.save(list);
    }

    public TrelloList getList(Long id) {
        return listRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("List not found"));
    }

    public TrelloList updateList(Long id, TrelloList updatedList) {
        TrelloList list = getList(id);
        list.setName(updatedList.getName());
        return listRepository.save(list);
    }

    public List<TrelloList> getAllLists() {
        return listRepository.findAll();
    }


    public void deleteList(Long id) {
        listRepository.deleteById(id);
    }
}
