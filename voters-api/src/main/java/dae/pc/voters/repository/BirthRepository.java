package dae.pc.voters.repository;

import dae.pc.voters.entity.Birth;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * Repository for Birth entity operations.
 */
@Repository
public interface BirthRepository extends BaseRepository<Birth, Integer> {

    Optional<Birth> findFirstByCitizenId(Integer citizenId);
}
