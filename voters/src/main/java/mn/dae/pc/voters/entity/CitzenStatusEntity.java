package mn.dae.pc.voters.entity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "citizenship_statuses")
@Getter
@Setter
public class CitzenStatusEntity {

    @Id
    @Column(name = "status_code")
    private Character statusCode;

    @Column(name = "status_description", nullable = false)
    private String statusDescription;
}
