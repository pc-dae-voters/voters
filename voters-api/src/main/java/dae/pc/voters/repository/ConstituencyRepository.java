package dae.pc.voters.repository;

import dae.pc.voters.entity.Constituency;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * Repository for Constituency entity operations.
 */
@Repository
public interface ConstituencyRepository extends BaseRepository<Constituency, Integer> {

    Optional<Constituency> findByCode(String code);

    @Query("SELECT DISTINCT c.nation FROM Constituency c WHERE c.nation IS NOT NULL ORDER BY c.nation")
    List<String> findNations();

    @Query("SELECT DISTINCT c.region FROM Constituency c WHERE c.region IS NOT NULL ORDER BY c.region")
    List<String> findRegions();
}
