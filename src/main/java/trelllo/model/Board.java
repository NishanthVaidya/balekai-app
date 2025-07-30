package trelllo.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import lombok.*;
import com.fasterxml.jackson.annotation.JsonManagedReference;
import java.util.List;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Board {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;
    private String ownerId;

    @OneToMany(mappedBy = "board", cascade = CascadeType.ALL, orphanRemoval = true)
    @JsonManagedReference
    private List<TrelloList> lists;
    @Column(name = "is_private") // 🔥 Maps to SQL column
    @JsonProperty("isPrivate")   // 🔥 Maps to JSON field for frontend
    private boolean aPrivate;

    public boolean isAPrivate() {
        return aPrivate;
    }
    // Add getter and setter for visibility
    @Getter
    private String visibility; // Add this field if missing


    public void setAPrivate(boolean aPrivate) {
        this.aPrivate = aPrivate;
    }
    @Setter
    @Getter
    private String ownerName; // ✅ Add this

}