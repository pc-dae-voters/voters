package dae.pc.voters.entity;

import jakarta.persistence.*;
import java.time.LocalDate;

/**
 * Entity representing a birth record.
 */
@Entity
@Table(name = "births")
public class Birth {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;
    
    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "citizen_id", unique = true, nullable = false)
    private Citizen citizen;
    
    @Column(name = "birth_date", nullable = false)
    private LocalDate birthDate;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "mother_id")
    private Citizen mother;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "father_id")
    private Citizen father;
    
    // Constructors
    public Birth() {}
    
    public Birth(Citizen citizen, LocalDate birthDate) {
        this.citizen = citizen;
        this.birthDate = birthDate;
    }
    
    public Birth(Citizen citizen, LocalDate birthDate, Citizen mother, Citizen father) {
        this.citizen = citizen;
        this.birthDate = birthDate;
        this.mother = mother;
        this.father = father;
    }
    
    // Getters and Setters
    public Integer getId() {
        return id;
    }
    
    public void setId(Integer id) {
        this.id = id;
    }
    
    public Citizen getCitizen() {
        return citizen;
    }
    
    public void setCitizen(Citizen citizen) {
        this.citizen = citizen;
    }
    
    public LocalDate getBirthDate() {
        return birthDate;
    }
    
    public void setBirthDate(LocalDate birthDate) {
        this.birthDate = birthDate;
    }
    
    public Citizen getMother() {
        return mother;
    }
    
    public void setMother(Citizen mother) {
        this.mother = mother;
    }
    
    public Citizen getFather() {
        return father;
    }
    
    public void setFather(Citizen father) {
        this.father = father;
    }
    
    // Helper methods
    public int getAge() {
        if (birthDate == null) {
            return 0;
        }
        return LocalDate.now().getYear() - birthDate.getYear();
    }
    
    public boolean isAdult() {
        return getAge() >= 18;
    }
    
    @Override
    public String toString() {
        return "Birth{" +
                "id=" + id +
                ", citizenId=" + (citizen != null ? citizen.getId() : null) +
                ", birthDate=" + birthDate +
                ", motherId=" + (mother != null ? mother.getId() : null) +
                ", fatherId=" + (father != null ? father.getId() : null) +
                '}';
    }
} 