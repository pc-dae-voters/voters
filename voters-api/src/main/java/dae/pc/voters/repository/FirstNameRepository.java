package dae.pc.voters.repository;

import dae.pc.voters.entity.FirstName;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * Repository for FirstName entity operations.
 */
@Repository
public interface FirstNameRepository extends BaseRepository<FirstName, Integer> {

    Optional<FirstName> findByNameIgnoreCase(String name);
}
