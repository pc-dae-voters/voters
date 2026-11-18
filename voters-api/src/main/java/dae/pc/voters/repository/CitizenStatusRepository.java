package dae.pc.voters.repository;

import dae.pc.voters.entity.CitizenStatus;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * Repository for CitizenStatus entity operations.
 */
@Repository
public interface CitizenStatusRepository extends BaseRepository<CitizenStatus, Integer> {

    Optional<CitizenStatus> findByCodeIgnoreCase(String code);
}
