package trelllo.model;

import jakarta.persistence.*;
import lombok.*;
import com.fasterxml.jackson.annotation.JsonIgnore;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Entity
@Table(name = "\"user\"") // Escape reserved keyword for PostgreSQL
public class User {

    @Id
    @Column(name = "id", nullable = false)
    private String id; // Firebase UID

    @Column(name = "email", nullable = false, unique = true)
    private String email;

    @Column(name = "name")
    private String name;

    @JsonIgnore
    @Column(name = "password")
    private String password; // May be empty for Firebase users
}
