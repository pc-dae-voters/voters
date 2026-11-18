package dae.pc.voters.repository;

import dae.pc.voters.entity.Surname;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * Repository for Surname entity operations.
 */
@Repository
public interface SurnameRepository extends BaseRepository<Surname, Integer> {

    Optional<Surname> findByNameIgnoreCase(String name);
}
