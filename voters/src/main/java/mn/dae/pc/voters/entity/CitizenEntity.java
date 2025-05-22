package mn.dae.pc.voters.entity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "citizens")
@Getter
@Setter
public class CitizenEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "surname", nullable = false)
    private String surname;

    @Column(name = "first_names", nullable = false)
    private String firstNames;

    @Column(name = "gender")
    private Character gender;

    @Column(name = "status")
    private Character status;

    @Column(name = "notes", columnDefinition = "TEXT")
    private String notes;
}
