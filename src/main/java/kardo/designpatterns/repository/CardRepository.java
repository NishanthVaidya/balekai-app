package kardo.designpatterns.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import kardo.designpatterns.model.Card;

import java.util.List;

public interface CardRepository extends JpaRepository<Card, Long> {
    List<Card> findByListId(Long listId);

}

