package dae.pc.voters.entity;

import jakarta.persistence.*;
import java.time.LocalDate;

/**
 * Entity representing a citizen's birth record, with their name at birth and their parents, see db/births.sql.
 * load-synthetic-people.py sets the date column, the table's birth_date column is unused.
 */
@Entity
@Table(name = "births")
public class Birth {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "citizen_id")
    private Citizen citizen;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "first_name_id")
    private FirstName firstName;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "surname_id")
    private Surname surname;

    @Column(name = "gender", length = 1)
    private String gender;

    @Column(name = "date", nullable = false)
    private LocalDate date;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "place_id")
    private Place place;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "father_id")
    private Citizen father;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "mother_id")
    private Citizen mother;

    public Birth() {}

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public Citizen getCitizen() { return citizen; }
    public void setCitizen(Citizen citizen) { this.citizen = citizen; }

    public FirstName getFirstName() { return firstName; }
    public void setFirstName(FirstName firstName) { this.firstName = firstName; }

    public Surname getSurname() { return surname; }
    public void setSurname(Surname surname) { this.surname = surname; }

    public String getGender() { return gender; }
    public void setGender(String gender) { this.gender = gender; }

    public LocalDate getDate() { return date; }
    public void setDate(LocalDate date) { this.date = date; }

    public Place getPlace() { return place; }
    public void setPlace(Place place) { this.place = place; }

    public Citizen getFather() { return father; }
    public void setFather(Citizen father) { this.father = father; }

    public Citizen getMother() { return mother; }
    public void setMother(Citizen mother) { this.mother = mother; }
}
