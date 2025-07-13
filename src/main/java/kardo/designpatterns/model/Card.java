package kardo.designpatterns.model;

import com.fasterxml.jackson.annotation.JsonBackReference;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Card {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String title;
    private String description;

    @ManyToOne
    @JoinColumn(name = "list_id")
    @JsonBackReference
    private TrelloList list;

    private String label;
    private String dueDate;

    @ManyToOne
    private User assignedUser;

    @ElementCollection
    private List<String> comments = new ArrayList<>();

    private LocalDateTime createdAt;

    // 🚀 NEW FIELDS
    private String currentState;  // e.g., "To Do", "In Progress", "Done"

    @ElementCollection
    private List<String> stateHistory = new ArrayList<>(); // ["Created -> To Do", "To Do -> In Progress"]
}
