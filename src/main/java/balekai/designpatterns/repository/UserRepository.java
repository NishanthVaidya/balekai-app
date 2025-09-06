package balekai.designpatterns.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import balekai.designpatterns.model.User;

import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, String> {
    Optional<User> findByEmail(String email);
    
    @Modifying
    @Query(value = "UPDATE \"user\" SET id = :newId WHERE id = :oldId", nativeQuery = true)
    void updateUserId(@Param("oldId") String oldId, @Param("newId") String newId);
}


