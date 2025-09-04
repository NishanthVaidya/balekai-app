package balekai.designpatterns.controller;

import balekai.designpatterns.model.TrelloList;
import balekai.designpatterns.repository.TrelloListRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Profile;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/lists")
@Profile("!test") // Don't load this controller in test profile
public class TrelloListController {

    @Autowired
    private TrelloListRepository trelloListRepository;

    @PostMapping("/{boardId}")
    public TrelloList createList(@PathVariable Long boardId, @RequestBody TrelloList list) {
        return trelloListRepository.save(list);
    }
    
    @PostMapping
    public TrelloList createList(@RequestBody TrelloList list) {
        return trelloListRepository.save(list);
    }

    @GetMapping
    public List<TrelloList> getAllLists() {
        return trelloListRepository.findAll();
    }

    @GetMapping("/{id}")
    public TrelloList getList(@PathVariable Long id) {
        return trelloListRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("List not found"));
    }

    @PutMapping("/{id}")
    public TrelloList updateList(@PathVariable Long id, @RequestBody TrelloList list) {
        TrelloList existingList = trelloListRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("List not found"));
        existingList.setName(list.getName());
        return trelloListRepository.save(existingList);
    }

    @DeleteMapping("/{id}")
    public void deleteList(@PathVariable Long id) {
        trelloListRepository.deleteById(id);
    }
}
