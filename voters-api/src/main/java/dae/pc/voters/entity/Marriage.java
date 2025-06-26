package dae.pc.voters.entity;

import jakarta.persistence.*;
import java.time.LocalDate;

/**
 * Entity representing a marriage between two citizens.
 */
@Entity
@Table(name = "marriages")
public class Marriage {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "person1_id", nullable = false)
    private Citizen person1;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "person2_id", nullable = false)
    private Citizen person2;
    
    @Column(name = "marriage_date", nullable = false)
    private LocalDate marriageDate;
    
    @Column(name = "divorce_date")
    private LocalDate divorceDate;
    
    // Constructors
    public Marriage() {}
    
    public Marriage(Citizen person1, Citizen person2, LocalDate marriageDate) {
        this.person1 = person1;
        this.person2 = person2;
        this.marriageDate = marriageDate;
    }
    
    // Getters and Setters
    public Integer getId() {
        return id;
    }
    
    public void setId(Integer id) {
        this.id = id;
    }
    
    public Citizen getPerson1() {
        return person1;
    }
    
    public void setPerson1(Citizen person1) {
        this.person1 = person1;
    }
    
    public Citizen getPerson2() {
        return person2;
    }
    
    public void setPerson2(Citizen person2) {
        this.person2 = person2;
    }
    
    public LocalDate getMarriageDate() {
        return marriageDate;
    }
    
    public void setMarriageDate(LocalDate marriageDate) {
        this.marriageDate = marriageDate;
    }
    
    public LocalDate getDivorceDate() {
        return divorceDate;
    }
    
    public void setDivorceDate(LocalDate divorceDate) {
        this.divorceDate = divorceDate;
    }
    
    // Helper methods
    public boolean isDivorced() {
        return divorceDate != null;
    }
    
    public boolean isActive() {
        return !isDivorced();
    }
    
    @Override
    public String toString() {
        return "Marriage{" +
                "id=" + id +
                ", person1Id=" + (person1 != null ? person1.getId() : null) +
                ", person2Id=" + (person2 != null ? person2.getId() : null) +
                ", marriageDate=" + marriageDate +
                ", divorceDate=" + divorceDate +
                '}';
    }
} 