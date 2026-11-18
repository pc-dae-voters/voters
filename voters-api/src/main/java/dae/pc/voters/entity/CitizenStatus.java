package dae.pc.voters.entity;

import jakarta.persistence.*;

/**
 * Entity representing a citizenship status, e.g. B for British Citizen, see db/citizen-status.sql.
 */
@Entity
@Table(name = "citizen_status")
public class CitizenStatus {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "code", length = 10, unique = true, nullable = false)
    private String code;

    @Column(name = "description")
    private String description;

    public CitizenStatus() {}

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public String getCode() { return code; }
    public void setCode(String code) { this.code = code; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
}
