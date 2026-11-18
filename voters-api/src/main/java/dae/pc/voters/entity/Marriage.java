package dae.pc.voters.entity;

import jakarta.persistence.*;
import java.time.LocalDate;

/**
 * Entity representing a marriage between two citizens, see db/marriages.sql.
 */
@Entity
@Table(name = "marriages")
public class Marriage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "partner1_id", nullable = false)
    private Citizen partner1;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "partner2_id", nullable = false)
    private Citizen partner2;

    @Column(name = "married_date", nullable = false)
    private LocalDate marriedDate;

    // NULL if still married
    @Column(name = "divorced_date")
    private LocalDate divorcedDate;

    public Marriage() {}

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public Citizen getPartner1() { return partner1; }
    public void setPartner1(Citizen partner1) { this.partner1 = partner1; }

    public Citizen getPartner2() { return partner2; }
    public void setPartner2(Citizen partner2) { this.partner2 = partner2; }

    public LocalDate getMarriedDate() { return marriedDate; }
    public void setMarriedDate(LocalDate marriedDate) { this.marriedDate = marriedDate; }

    public LocalDate getDivorcedDate() { return divorcedDate; }
    public void setDivorcedDate(LocalDate divorcedDate) { this.divorcedDate = divorcedDate; }
}
