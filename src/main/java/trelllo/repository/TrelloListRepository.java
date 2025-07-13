package trelllo.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import trelllo.model.TrelloList;

public interface TrelloListRepository extends JpaRepository<TrelloList, Long> {
}
