package balekai.designpatterns.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import balekai.designpatterns.model.TrelloList;

public interface TrelloListRepository extends JpaRepository<TrelloList, Long> {
}
