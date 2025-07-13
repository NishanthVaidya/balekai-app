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
    @GeneratedValue(strategy = GenerationType.IDENTITY) // or AUTO, depending on DB
   // @Column(name = "id", nullable = false)
    private String id; // Now Firebase UID or assigned string

    @Column(name = "email", nullable = false, unique = true)
    private String email;

    @Column(name = "name")
    private String name;

    @JsonIgnore
    @Column(name = "password")
    private String password; // May be empty for Firebase users
}
