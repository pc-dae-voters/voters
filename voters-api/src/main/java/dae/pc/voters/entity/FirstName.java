package dae.pc.voters.entity;

import jakarta.persistence.*;

/**
 * Entity representing a first name, see db/first-names.sql.
 */
@Entity
@Table(name = "first_names")
public class FirstName {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "name", nullable = false, unique = true)
    private String name;

    // M or F, the gender the name is usually given to
    @Column(name = "gender", length = 1)
    private String gender;

    public FirstName() {}

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getGender() { return gender; }
    public void setGender(String gender) { this.gender = gender; }
}
