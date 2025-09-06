package balekai.designpatterns.controller;

import balekai.designpatterns.model.TrelloList;
import balekai.designpatterns.repository.TrelloListRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Profile;
import org.springframework.transaction.annotation.Transactional;
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
    @Transactional(readOnly = true)
    public List<TrelloList> getAllLists() {
        List<TrelloList> lists = trelloListRepository.findAll();
        
        // Initialize lazy collections to avoid Hibernate lazy loading issues
        lists.forEach(list -> {
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
        
        return lists;
    }

    @GetMapping("/{id}")
    @Transactional(readOnly = true)
    public TrelloList getList(@PathVariable Long id) {
        TrelloList list = trelloListRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("List not found"));
        
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
        
        return list;
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
