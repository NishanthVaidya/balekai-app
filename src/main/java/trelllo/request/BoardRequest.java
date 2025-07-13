package trelllo.request;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;
import lombok.Getter;
import lombok.Setter;

@Data
public class BoardRequest {

    private String name;
    private String ownerId;

    @JsonProperty("isPrivate")
    private boolean aPrivate;

    @Setter
    @Getter
    private String ownerName; // ✅

}
