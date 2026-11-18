package dae.pc.voters.repository;

import dae.pc.voters.entity.Country;
import org.springframework.stereotype.Repository;

/**
 * Repository for Country entity operations.
 */
@Repository
public interface CountryRepository extends BaseRepository<Country, Integer> {
}
