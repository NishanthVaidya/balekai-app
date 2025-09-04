package balekai.designpatterns.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import balekai.designpatterns.model.Card;

import java.util.List;

public interface CardRepository extends JpaRepository<Card, Long> {
    List<Card> findByListId(Long listId);

}

