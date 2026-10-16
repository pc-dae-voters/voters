package dae.pc.voters.entity;

import jakarta.persistence.*;
import java.time.LocalDate;

/**
 * Entity representing a citizen in the system.
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
    
    @Enumerated(EnumType.STRING)
    @Column(name = "gender", length = 1)
    private Gender gender;
    
    @Column(name = "died")
    private LocalDate died;
    
    // Constructors
    public Citizen() {}
    
    public Citizen(Integer id, CitizenStatus status, Surname surname, FirstName firstName, Gender gender) {
        this.id = id;
        this.status = status;
        this.surname = surname;
        this.firstName = firstName;
        this.gender = gender;
    }
    
    // Getters and Setters
    public Integer getId() {
        return id;
    }
    
    public void setId(Integer id) {
        this.id = id;
    }
    
    public CitizenStatus getStatus() {
        return status;
    }
    
    public void setStatus(CitizenStatus status) {
        this.status = status;
    }
    
    public Surname getSurname() {
        return surname;
    }
    
    public void setSurname(Surname surname) {
        this.surname = surname;
    }
    
    public FirstName getFirstName() {
        return firstName;
    }
    
    public void setFirstName(FirstName firstName) {
        this.firstName = firstName;
    }
    
    public Gender getGender() {
        return gender;
    }
    
    public void setGender(Gender gender) {
        this.gender = gender;
    }
    
    public LocalDate getDied() {
        return died;
    }
    
    public void setDied(LocalDate died) {
        this.died = died;
    }
    
    // Helper methods
    public boolean isAlive() {
        return died == null;
    }
    
    public String getFullName() {
        if (firstName != null && surname != null) {
            return firstName.getName() + " " + surname.getName();
        }
        return "Unknown";
    }
    
    @Override
    public String toString() {
        return "Citizen{" +
                "id=" + id +
                ", fullName='" + getFullName() + '\'' +
                ", gender=" + gender +
                ", died=" + died +
                '}';
    }
    
    public enum Gender {
        M, F
    }
} 