package dae.pc.voters.entity;

import jakarta.persistence.*;

/**
 * Entity representing a parliamentary constituency, see db/constituencies.sql.
 */
@Entity
@Table(name = "constituencies")
public class Constituency {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    // The ONS code, e.g. E14001063, "con-postcodes".con_code references it
    @Column(name = "code", unique = true)
    private String code;

    @Column(name = "name", nullable = false)
    private String name;

    @Column(name = "tla", length = 3)
    private String tla;

    @Column(name = "nation")
    private String nation;

    @Column(name = "region")
    private String region;

    // Constituency type, e.g. County or Borough
    @Column(name = "ctype")
    private String ctype;

    @Column(name = "area")
    private Float area;

    public Constituency() {}

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public String getCode() { return code; }
    public void setCode(String code) { this.code = code; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getTla() { return tla; }
    public void setTla(String tla) { this.tla = tla; }

    public String getNation() { return nation; }
    public void setNation(String nation) { this.nation = nation; }

    public String getRegion() { return region; }
    public void setRegion(String region) { this.region = region; }

    public String getCtype() { return ctype; }
    public void setCtype(String ctype) { this.ctype = ctype; }

    public Float getArea() { return area; }
    public void setArea(Float area) { this.area = area; }
}
