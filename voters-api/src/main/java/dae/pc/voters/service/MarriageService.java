package dae.pc.voters.service;

import dae.pc.voters.dto.MarriageDto;
import dae.pc.voters.entity.Marriage;
import dae.pc.voters.repository.CitizenRepository;
import dae.pc.voters.repository.MarriageRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;

/**
 * Service for marriages. List filters: citizenId, either partner, and current, true for marriages that have not
 * ended in divorce.
 */
@Service
public class MarriageService extends CrudService<Marriage, MarriageDto, Integer> {

    private final CitizenRepository citizenRepository;

    @Autowired
    public MarriageService(MarriageRepository repository, CitizenRepository citizenRepository) {
        super(repository, "Marriage");
        this.citizenRepository = citizenRepository;
    }

    @Override
    protected MarriageDto toDto(Marriage m) {
        var p1 = m.getPartner1();
        var p2 = m.getPartner2();
        return new MarriageDto(m.getId(),
                p1 != null ? p1.getId() : null, Names.of(p1),
                p2 != null ? p2.getId() : null, Names.of(p2),
                m.getMarriedDate(), m.getDivorcedDate());
    }

    @Override
    protected Marriage newEntity() {
        return new Marriage();
    }

    @Override
    protected void apply(MarriageDto dto, Marriage m) {
        if (dto.partner1Id().equals(dto.partner2Id())) {
            throw new BadRequestException("A citizen can't marry themselves");
        }
        if (dto.divorcedDate() != null && dto.divorcedDate().isBefore(dto.marriedDate())) {
            throw new BadRequestException("The divorce date is before the marriage date");
        }
        m.setPartner1(reference(citizenRepository, dto.partner1Id(), "Citizen"));
        m.setPartner2(reference(citizenRepository, dto.partner2Id(), "Citizen"));
        m.setMarriedDate(dto.marriedDate());
        m.setDivorcedDate(dto.divorcedDate());
    }

    @Override
    protected Specification<Marriage> filter(Filters<Marriage> filters) {
        return filters
                .add(filters.getInt("citizenId"), id -> (root, query, cb) -> cb.or(
                        cb.equal(root.get("partner1").get("id"), id), cb.equal(root.get("partner2").get("id"), id)))
                .add(filters.getBoolean("current"), current -> (root, query, cb) ->
                        current ? cb.isNull(root.get("divorcedDate")) : cb.isNotNull(root.get("divorcedDate")))
                .build();
    }
}
