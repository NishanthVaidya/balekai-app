package trelllo.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import trelllo.model.Card;
import trelllo.model.TrelloList;
import trelllo.repository.CardRepository;
import trelllo.repository.TrelloListRepository;

import java.util.List;

@Service
public class CardService {

    @Autowired
    private CardRepository cardRepository;

    @Autowired
    private TrelloListRepository listRepository;

    public Card createCard(Card card) {
        Long listId = card.getList().getId();
        TrelloList list = listRepository.findById(listId)
                .orElseThrow(() -> new RuntimeException("List not found"));
        card.setList(list);
        return cardRepository.save(card);
    }

    public void deleteCardsByListId(Long listId) {
        List<Card> cards = cardRepository.findByListId(listId);
        cardRepository.deleteAll(cards);
    }


    public List<Card> getCardsByList(Long listId) {
        return cardRepository.findByListId(listId);
    }

    public Card updateCard(Long id, Card updatedCard) {
        Card card = cardRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Card not found"));
        card.setTitle(updatedCard.getTitle());
        card.setDescription(updatedCard.getDescription());
        card.setLabel(updatedCard.getLabel());
        card.setDueDate(updatedCard.getDueDate());
        return cardRepository.save(card);
    }

    public void deleteCard(Long id) {
        cardRepository.deleteById(id);
    }
}
