package dae.pc.voters.entity;

import jakarta.persistence.*;

/**
 * Entity representing surnames.
 */
@Entity
@Table(name = "surnames")
public class Surname {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;
    
    @Column(name = "name", nullable = false)
    private String name;
    
    // Constructors
    public Surname() {}
    
    public Surname(String name) {
        this.name = name;
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
    
    @Override
    public String toString() {
        return "Surname{" +
                "id=" + id +
                ", name='" + name + '\'' +
                '}';
    }
} 