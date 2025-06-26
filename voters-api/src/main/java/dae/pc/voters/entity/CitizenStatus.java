package dae.pc.voters.entity;

import jakarta.persistence.*;

/**
 * Entity representing citizen status codes.
 */
@Entity
@Table(name = "citizen-status")
public class CitizenStatus {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;
    
    @Column(name = "code", length = 10, unique = true, nullable = false)
    private String code;
    
    @Column(name = "description")
    private String description;
    
    // Constructors
    public CitizenStatus() {}
    
    public CitizenStatus(String code, String description) {
        this.code = code;
        this.description = description;
    }
    
    // Getters and Setters
    public Integer getId() {
        return id;
    }
    
    public void setId(Integer id) {
        this.id = id;
    }
    
    public String getCode() {
        return code;
    }
    
    public void setCode(String code) {
        this.code = code;
    }
    
    public String getDescription() {
        return description;
    }
    
    public void setDescription(String description) {
        this.description = description;
    }
    
    @Override
    public String toString() {
        return "CitizenStatus{" +
                "id=" + id +
                ", code='" + code + '\'' +
                ", description='" + description + '\'' +
                '}';
    }
} 