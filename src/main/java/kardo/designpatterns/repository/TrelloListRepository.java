package kardo.designpatterns.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import kardo.designpatterns.model.TrelloList;

public interface TrelloListRepository extends JpaRepository<TrelloList, Long> {
}
