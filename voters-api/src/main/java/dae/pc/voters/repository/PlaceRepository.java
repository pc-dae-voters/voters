package dae.pc.voters.repository;

import dae.pc.voters.entity.Place;
import org.springframework.stereotype.Repository;

/**
 * Repository for Place entity operations.
 */
@Repository
public interface PlaceRepository extends BaseRepository<Place, Integer> {
}
