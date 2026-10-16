package dae.pc.voters.entity;

import jakarta.persistence.*;

/**
 * Entity representing a parliamentary constituency.
 */
@Entity
@Table(name = "constituencies")
public class Constituency {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;
    
    @Column(name = "name", nullable = false)
    private String name;
    
    @Column(name = "code", length = 10, unique = true)
    private String code;
    
    // Constructors
    public Constituency() {}
    
    public Constituency(String name, String code) {
        this.name = name;
        this.code = code;
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
    
    public String getCode() {
        return code;
    }
    
    public void setCode(String code) {
        this.code = code;
    }
    
    @Override
    public String toString() {
        return "Constituency{" +
                "id=" + id +
                ", name='" + name + '\'' +
                ", code='" + code + '\'' +
                '}';
    }
} 