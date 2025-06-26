package dae.pc.voters.repository;

import dae.pc.voters.entity.Citizen;
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
 * Repository for Citizen entity operations.
 */
@Repository
public interface CitizenRepository extends JpaRepository<Citizen, Integer> {
    
    /**
     * Find citizens by gender.
     */
    List<Citizen> findByGender(Citizen.Gender gender);
    
    /**
     * Find citizens by status code.
     */
    @Query("SELECT c FROM Citizen c JOIN c.status s WHERE s.code = :statusCode")
    List<Citizen> findByStatusCode(@Param("statusCode") String statusCode);
    
    /**
     * Find citizens by surname.
     */
    @Query("SELECT c FROM Citizen c JOIN c.surname s WHERE s.name = :surname")
    List<Citizen> findBySurname(@Param("surname") String surname);
    
    /**
     * Find citizens by first name.
     */
    @Query("SELECT c FROM Citizen c JOIN c.firstName f WHERE f.name = :firstName")
    List<Citizen> findByFirstName(@Param("firstName") String firstName);
    
    /**
     * Find citizens by full name (first name and surname).
     */
    @Query("SELECT c FROM Citizen c JOIN c.firstName f JOIN c.surname s WHERE f.name = :firstName AND s.name = :surname")
    List<Citizen> findByFullName(@Param("firstName") String firstName, @Param("surname") String surname);
    
    /**
     * Find alive citizens (where died is null).
     */
    List<Citizen> findByDiedIsNull();
    
    /**
     * Find citizens who died on a specific date.
     */
    List<Citizen> findByDied(LocalDate died);
    
    /**
     * Find citizens who died between two dates.
     */
    List<Citizen> findByDiedBetween(LocalDate startDate, LocalDate endDate);
    
    /**
     * Find citizens with pagination.
     */
    Page<Citizen> findAll(Pageable pageable);
    
    /**
     * Find alive citizens with pagination.
     */
    Page<Citizen> findByDiedIsNull(Pageable pageable);
    
    /**
     * Search citizens by name (partial match on first name or surname).
     */
    @Query("SELECT c FROM Citizen c JOIN c.firstName f JOIN c.surname s " +
           "WHERE LOWER(f.name) LIKE LOWER(CONCAT('%', :searchTerm, '%')) " +
           "OR LOWER(s.name) LIKE LOWER(CONCAT('%', :searchTerm, '%'))")
    List<Citizen> searchByName(@Param("searchTerm") String searchTerm);
    
    /**
     * Count citizens by gender.
     */
    long countByGender(Citizen.Gender gender);
    
    /**
     * Count alive citizens.
     */
    long countByDiedIsNull();
} 