package balekai.designpatterns.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import balekai.designpatterns.model.Card;

import java.util.List;

public interface CardRepository extends JpaRepository<Card, Long> {
    List<Card> findByListId(Long listId);
    
    @Modifying
    @Query("UPDATE Card c SET c.assignedUser.id = :newUserId WHERE c.assignedUser.id = :oldUserId")
    void updateAssignedUserId(@Param("oldUserId") String oldUserId, @Param("newUserId") String newUserId);
}

