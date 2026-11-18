package dae.pc.voters.repository;

import dae.pc.voters.entity.CitizenChange;
import org.springframework.stereotype.Repository;

/**
 * Repository for CitizenChange entity operations.
 */
@Repository
public interface CitizenChangeRepository extends BaseRepository<CitizenChange, Integer> {
}
