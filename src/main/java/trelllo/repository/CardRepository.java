package trelllo.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import trelllo.model.Card;

import java.util.List;

public interface CardRepository extends JpaRepository<Card, Long> {
    List<Card> findByListId(Long listId);

}

