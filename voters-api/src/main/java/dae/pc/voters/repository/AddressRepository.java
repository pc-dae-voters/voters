package dae.pc.voters.repository;

import dae.pc.voters.entity.Address;
import org.springframework.stereotype.Repository;

/**
 * Repository for Address entity operations.
 */
@Repository
public interface AddressRepository extends BaseRepository<Address, Integer> {
}
