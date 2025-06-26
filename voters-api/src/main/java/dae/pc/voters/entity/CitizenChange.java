package dae.pc.voters.entity;

import jakarta.persistence.*;
import org.hibernate.annotations.Type;
import java.time.LocalDate;
import java.util.Map;

/**
 * Entity representing changes to citizen records.
 */
@Entity
@Table(name = "citizen-changes")
public class CitizenChange {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "citizen_id", nullable = false)
    private Citizen citizen;
    
    @Column(name = "change_date", nullable = false)
    private LocalDate changeDate;
    
    @Column(name = "details", columnDefinition = "jsonb")
    private String details; // JSON string for flexible change tracking
    
    // Constructors
    public CitizenChange() {}
    
    public CitizenChange(Citizen citizen, LocalDate changeDate, String details) {
        this.citizen = citizen;
        this.changeDate = changeDate;
        this.details = details;
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
    
    public LocalDate getChangeDate() {
        return changeDate;
    }
    
    public void setChangeDate(LocalDate changeDate) {
        this.changeDate = changeDate;
    }
    
    public String getDetails() {
        return details;
    }
    
    public void setDetails(String details) {
        this.details = details;
    }
    
    @Override
    public String toString() {
        return "CitizenChange{" +
                "id=" + id +
                ", citizenId=" + (citizen != null ? citizen.getId() : null) +
                ", changeDate=" + changeDate +
                ", details='" + details + '\'' +
                '}';
    }
} 