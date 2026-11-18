package dae.pc.voters.entity;

import jakarta.persistence.*;

/**
 * Entity mapping a postcode to its constituency's code, see db/con-postcodes.sql. Postcodes are stored in upper case
 * without spaces, as load-con-postcodes.py and load-addresses.py normalise them.
 */
@Entity
@Table(name = "\"con-postcodes\"")
public class ConPostcode {

    @Id
    @Column(name = "postcode", length = 15)
    private String postcode;

    @Column(name = "con_code")
    private String conCode;

    public ConPostcode() {}

    public String getPostcode() { return postcode; }
    public void setPostcode(String postcode) { this.postcode = postcode; }

    public String getConCode() { return conCode; }
    public void setConCode(String conCode) { this.conCode = conCode; }
}
