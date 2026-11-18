package dae.pc.voters.entity;

import jakarta.persistence.*;

/**
 * Entity representing a surname, see db/surnames.sql.
 */
@Entity
@Table(name = "surnames")
public class Surname {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "name", nullable = false, unique = true)
    private String name;

    public Surname() {}

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
}
