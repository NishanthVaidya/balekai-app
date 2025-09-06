package balekai.designpatterns.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import balekai.designpatterns.model.Board;

import java.util.List;

public interface BoardRepository extends JpaRepository<Board, Long> {
    List<Board> findByOwnerId(String ownerId);
    
    @Modifying
    @Query("UPDATE Board b SET b.ownerId = :newOwnerId WHERE b.ownerId = :oldOwnerId")
    void updateOwnerId(@Param("oldOwnerId") String oldOwnerId, @Param("newOwnerId") String newOwnerId);
}
