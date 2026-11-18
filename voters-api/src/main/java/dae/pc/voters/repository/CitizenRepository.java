package dae.pc.voters.repository;

import dae.pc.voters.entity.Citizen;
import org.springframework.stereotype.Repository;

/**
 * Repository for Citizen entity operations.
 */
@Repository
public interface CitizenRepository extends BaseRepository<Citizen, Integer> {

    long countByDiedIsNull();

    long countByGender(String gender);
}
