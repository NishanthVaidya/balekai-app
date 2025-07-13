package trelllo.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import trelllo.model.Board;

import java.util.List;

public interface BoardRepository extends JpaRepository<Board, Long> {
    List<Board> findByOwnerId(String ownerId);
}
