package dae.pc.voters.repository;

import dae.pc.voters.entity.Surname;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

/**
 * Repository for Surname entity operations.
 */
@Repository
public interface SurnameRepository extends JpaRepository<Surname, Integer> {
    
    /**
     * Find surname by name.
     */
    Surname findByName(String name);
} 