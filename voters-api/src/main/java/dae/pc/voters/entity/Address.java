package dae.pc.voters.entity;

import jakarta.persistence.*;

/**
 * Entity representing an address.
 */
@Entity
@Table(name = "addresses")
public class Address {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;
    
    @Column(name = "address", nullable = false)
    private String address;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "place_id")
    private Place place;
    
    @Column(name = "postcode")
    private String postcode;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "constituency_id")
    private Constituency constituency;
    
    // Constructors
    public Address() {}
    
    public Address(String address, Place place, String postcode, Constituency constituency) {
        this.address = address;
        this.place = place;
        this.postcode = postcode;
        this.constituency = constituency;
    }
    
    // Getters and Setters
    public Integer getId() {
        return id;
    }
    
    public void setId(Integer id) {
        this.id = id;
    }
    
    public String getAddress() {
        return address;
    }
    
    public void setAddress(String address) {
        this.address = address;
    }
    
    public Place getPlace() {
        return place;
    }
    
    public void setPlace(Place place) {
        this.place = place;
    }
    
    public String getPostcode() {
        return postcode;
    }
    
    public void setPostcode(String postcode) {
        this.postcode = postcode;
    }
    
    public Constituency getConstituency() {
        return constituency;
    }
    
    public void setConstituency(Constituency constituency) {
        this.constituency = constituency;
    }
    
    @Override
    public String toString() {
        return "Address{" +
                "id=" + id +
                ", address='" + address + '\'' +
                ", placeId=" + (place != null ? place.getId() : null) +
                ", postcode='" + postcode + '\'' +
                ", constituencyId=" + (constituency != null ? constituency.getId() : null) +
                '}';
    }
} 