package trelllo.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import trelllo.model.Card;

import java.util.List;

public interface CardRepository extends JpaRepository<Card, Long> {
    List<Card> findByListId(Long listId);
    
    @Modifying
    @Query(value = "DELETE FROM card WHERE id = :cardId", nativeQuery = true)
    void deleteCardById(@Param("cardId") Long cardId);
    
    @Modifying
    @Query(value = "DELETE FROM card_state_history WHERE card_id = :cardId", nativeQuery = true)
    void deleteCardStateHistory(@Param("cardId") Long cardId);
    
    @Modifying
    @Query(value = "DELETE FROM card_comments WHERE card_id = :cardId", nativeQuery = true)
    void deleteCardComments(@Param("cardId") Long cardId);
}

