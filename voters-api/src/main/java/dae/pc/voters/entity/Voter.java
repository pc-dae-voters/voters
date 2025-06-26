package dae.pc.voters.entity;

import jakarta.persistence.*;
import java.time.LocalDate;

/**
 * Entity representing a registered voter.
 */
@Entity
@Table(name = "voters")
public class Voter {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "citizen_id", unique = true, nullable = false)
    private Citizen citizen;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "address_id", nullable = false)
    private Address address;
    
    @Column(name = "open_register")
    private Boolean openRegister = false;
    
    @Column(name = "registration_date", nullable = false)
    private LocalDate registrationDate;
    
    // Constructors
    public Voter() {}
    
    public Voter(Citizen citizen, Address address, Boolean openRegister, LocalDate registrationDate) {
        this.citizen = citizen;
        this.address = address;
        this.openRegister = openRegister;
        this.registrationDate = registrationDate;
    }
    
    // Getters and Setters
    public Long getId() {
        return id;
    }
    
    public void setId(Long id) {
        this.id = id;
    }
    
    public Citizen getCitizen() {
        return citizen;
    }
    
    public void setCitizen(Citizen citizen) {
        this.citizen = citizen;
    }
    
    public Address getAddress() {
        return address;
    }
    
    public void setAddress(Address address) {
        this.address = address;
    }
    
    public Boolean getOpenRegister() {
        return openRegister;
    }
    
    public void setOpenRegister(Boolean openRegister) {
        this.openRegister = openRegister;
    }
    
    public LocalDate getRegistrationDate() {
        return registrationDate;
    }
    
    public void setRegistrationDate(LocalDate registrationDate) {
        this.registrationDate = registrationDate;
    }
    
    // Helper methods
    public boolean isOnOpenRegister() {
        return openRegister != null && openRegister;
    }
    
    @Override
    public String toString() {
        return "Voter{" +
                "id=" + id +
                ", citizenId=" + (citizen != null ? citizen.getId() : null) +
                ", addressId=" + (address != null ? address.getId() : null) +
                ", openRegister=" + openRegister +
                ", registrationDate=" + registrationDate +
                '}';
    }
} 