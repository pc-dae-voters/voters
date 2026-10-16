package dae.pc.voters.repository;

import dae.pc.voters.entity.Voter;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

/**
 * Repository for Voter entity operations.
 */
@Repository
public interface VoterRepository extends JpaRepository<Voter, Long> {
    
    /**
     * Find voter by citizen ID.
     */
    Optional<Voter> findByCitizenId(Integer citizenId);
    
    /**
     * Find voters by address ID.
     */
    List<Voter> findByAddressId(Integer addressId);
    
    /**
     * Find voters by constituency ID.
     */
    @Query("SELECT v FROM Voter v JOIN v.address a JOIN a.constituency c WHERE c.id = :constituencyId")
    List<Voter> findByConstituencyId(@Param("constituencyId") Integer constituencyId);
    
    /**
     * Find voters by constituency name.
     */
    @Query("SELECT v FROM Voter v JOIN v.address a JOIN a.constituency c WHERE c.name = :constituencyName")
    List<Voter> findByConstituencyName(@Param("constituencyName") String constituencyName);
    
    /**
     * Find voters by postcode.
     */
    @Query("SELECT v FROM Voter v JOIN v.address a WHERE a.postcode = :postcode")
    List<Voter> findByPostcode(@Param("postcode") String postcode);
    
    /**
     * Find voters on the open register.
     */
    List<Voter> findByOpenRegisterTrue();
    
    /**
     * Find voters not on the open register.
     */
    List<Voter> findByOpenRegisterFalse();
    
    /**
     * Find voters by registration date.
     */
    List<Voter> findByRegistrationDate(LocalDate registrationDate);
    
    /**
     * Find voters registered between two dates.
     */
    List<Voter> findByRegistrationDateBetween(LocalDate startDate, LocalDate endDate);
    
    /**
     * Find voters with pagination.
     */
    Page<Voter> findAll(Pageable pageable);
    
    /**
     * Find voters on open register with pagination.
     */
    Page<Voter> findByOpenRegisterTrue(Pageable pageable);
    
    /**
     * Count voters by constituency.
     */
    @Query("SELECT COUNT(v) FROM Voter v JOIN v.address a JOIN a.constituency c WHERE c.id = :constituencyId")
    long countByConstituencyId(@Param("constituencyId") Integer constituencyId);
    
    /**
     * Count voters on open register.
     */
    long countByOpenRegisterTrue();
    
    /**
     * Count voters not on open register.
     */
    long countByOpenRegisterFalse();
    
    /**
     * Find voters by place name.
     */
    @Query("SELECT v FROM Voter v JOIN v.address a JOIN a.place p WHERE p.name = :placeName")
    List<Voter> findByPlaceName(@Param("placeName") String placeName);
    
    /**
     * Find voters by country name.
     */
    @Query("SELECT v FROM Voter v JOIN v.address a JOIN a.place p JOIN p.country c WHERE c.name = :countryName")
    List<Voter> findByCountryName(@Param("countryName") String countryName);
} 