package dae.pc.voters.entity;

import jakarta.persistence.*;

/**
 * Entity representing first names.
 */
@Entity
@Table(name = "first-names")
public class FirstName {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;
    
    @Column(name = "name", nullable = false)
    private String name;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "gender", length = 1)
    private Citizen.Gender gender;
    
    // Constructors
    public FirstName() {}
    
    public FirstName(String name, Citizen.Gender gender) {
        this.name = name;
        this.gender = gender;
    }
    
    // Getters and Setters
    public Integer getId() {
        return id;
    }
    
    public void setId(Integer id) {
        this.id = id;
    }
    
    public String getName() {
        return name;
    }
    
    public void setName(String name) {
        this.name = name;
    }
    
    public Citizen.Gender getGender() {
        return gender;
    }
    
    public void setGender(Citizen.Gender gender) {
        this.gender = gender;
    }
    
    @Override
    public String toString() {
        return "FirstName{" +
                "id=" + id +
                ", name='" + name + '\'' +
                ", gender=" + gender +
                '}';
    }
} 