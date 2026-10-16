package dae.pc.voters.repository;

import dae.pc.voters.entity.Citizen;
import dae.pc.voters.entity.FirstName;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * Repository for FirstName entity operations.
 */
@Repository
public interface FirstNameRepository extends JpaRepository<FirstName, Integer> {
    
    /**
     * Find first names by gender.
     */
    List<FirstName> findByGender(Citizen.Gender gender);
    
    /**
     * Find first name by name.
     */
    FirstName findByName(String name);
} 