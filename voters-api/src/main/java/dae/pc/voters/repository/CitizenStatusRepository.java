package dae.pc.voters.repository;

import dae.pc.voters.entity.CitizenStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * Repository for CitizenStatus entity operations.
 */
@Repository
public interface CitizenStatusRepository extends JpaRepository<CitizenStatus, Integer> {
    
    /**
     * Find status by code.
     */
    Optional<CitizenStatus> findByCode(String code);
} 