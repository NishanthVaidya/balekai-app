package trelllo.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import trelllo.model.TrelloList;
import trelllo.service.TrelloListService;

import java.util.List;

@RestController
@RequestMapping("/lists")
public class TrelloListController {

    @Autowired
    private TrelloListService trelloListService;

    @PostMapping("/{boardId}")
    public TrelloList createList(@PathVariable Long boardId, @RequestBody TrelloList list) {
        return trelloListService.createList(boardId, list);
    }
    @PostMapping
    public TrelloList createList(@RequestBody TrelloList list) {
        Long boardId = list.getBoard().getId();
        return trelloListService.createList(boardId, list);
    }


    @GetMapping
    public List<TrelloList> getAllLists() {
        return trelloListService.getAllLists();
    }


    @GetMapping("/{id}")
    public TrelloList getList(@PathVariable Long id) {
        return trelloListService.getList(id);
    }

    @PutMapping("/{id}")
    public TrelloList updateList(@PathVariable Long id, @RequestBody TrelloList list) {
        return trelloListService.updateList(id, list);
    }

    @DeleteMapping("/{id}")
    public void deleteList(@PathVariable Long id) {
        trelloListService.deleteList(id);
    }
}
