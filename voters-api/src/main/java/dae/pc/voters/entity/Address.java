package dae.pc.voters.entity;

import jakarta.persistence.*;

/**
 * Entity representing an address, see db/addresses.sql. load-addresses.py leaves constituency_id NULL, the
 * constituency is found from the postcode using the con-postcodes table, see AddressService.constituencyOf.
 */
@Entity
@Table(name = "addresses")
public class Address {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "address")
    private String address;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "place_id")
    private Place place;

    @Column(name = "postcode", length = 10)
    private String postcode;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "constituency_id")
    private Constituency constituency;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "country_id")
    private Country country;

    public Address() {}

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }

    public Place getPlace() { return place; }
    public void setPlace(Place place) { this.place = place; }

    public String getPostcode() { return postcode; }
    public void setPostcode(String postcode) { this.postcode = postcode; }

    public Constituency getConstituency() { return constituency; }
    public void setConstituency(Constituency constituency) { this.constituency = constituency; }

    public Country getCountry() { return country; }
    public void setCountry(Country country) { this.country = country; }
}
