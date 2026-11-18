package dae.pc.voters.repository;

import dae.pc.voters.entity.Voter;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * Repository for Voter entity operations.
 */
@Repository
public interface VoterRepository extends BaseRepository<Voter, Long> {

    Optional<Voter> findByCitizenId(Integer citizenId);

    long countByOpenRegisterTrue();
}
