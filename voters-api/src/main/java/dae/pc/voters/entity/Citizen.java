package dae.pc.voters.entity;

import jakarta.persistence.*;
import java.time.LocalDate;

/**
 * Entity representing a citizen with their current name and status, see db/citizen.sql.
 */
@Entity
@Table(name = "citizen")
public class Citizen {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "status_id")
    private CitizenStatus status;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "surname_id")
    private Surname surname;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "first_name_id")
    private FirstName firstName;

    // M or F, the table has a check constraint
    @Column(name = "gender", length = 1)
    private String gender;

    // NULL if still alive
    @Column(name = "died")
    private LocalDate died;

    public Citizen() {}

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public CitizenStatus getStatus() { return status; }
    public void setStatus(CitizenStatus status) { this.status = status; }

    public Surname getSurname() { return surname; }
    public void setSurname(Surname surname) { this.surname = surname; }

    public FirstName getFirstName() { return firstName; }
    public void setFirstName(FirstName firstName) { this.firstName = firstName; }

    public String getGender() { return gender; }
    public void setGender(String gender) { this.gender = gender; }

    public LocalDate getDied() { return died; }
    public void setDied(LocalDate died) { this.died = died; }

    public String getFullName() {
        String first = firstName != null ? firstName.getName() : null;
        String last = surname != null ? surname.getName() : null;
        if (first == null && last == null) {
            return "Unknown";
        }
        return ((first != null ? first : "") + " " + (last != null ? last : "")).trim();
    }
}
