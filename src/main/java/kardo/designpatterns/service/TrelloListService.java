package kardo.designpatterns.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import kardo.designpatterns.model.TrelloList;
import kardo.designpatterns.model.Board;
import kardo.designpatterns.repository.TrelloListRepository;
import kardo.designpatterns.repository.BoardRepository;

import java.util.List;

@Service
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
