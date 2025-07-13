package kardo.designpatterns.model;

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
    // Removed @GeneratedValue since we're using String IDs (Firebase UIDs)
    private String id; // Firebase UID or manually assigned string

    @Column(name = "email", nullable = false, unique = true)
    private String email;

    @Column(name = "name")
    private String name;

    @JsonIgnore
    @Column(name = "password")
    private String password; // May be empty for Firebase users
}
