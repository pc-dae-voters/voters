package dae.pc.voters.service;

import dae.pc.voters.dto.CitizenChangeDto;
import dae.pc.voters.entity.CitizenChange;
import dae.pc.voters.repository.CitizenChangeRepository;
import dae.pc.voters.repository.CitizenRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;

/**
 * Service for changes to citizens' records. List filters: citizenId.
 */
@Service
public class CitizenChangeService extends CrudService<CitizenChange, CitizenChangeDto, Integer> {

    private final CitizenRepository citizenRepository;

    @Autowired
    public CitizenChangeService(CitizenChangeRepository repository, CitizenRepository citizenRepository) {
        super(repository, "Citizen change");
        this.citizenRepository = citizenRepository;
    }

    @Override
    protected CitizenChangeDto toDto(CitizenChange change) {
        var citizen = change.getCitizen();
        return new CitizenChangeDto(change.getId(), citizen != null ? citizen.getId() : null, Names.of(citizen),
                change.getChangeDate(), change.getDetails());
    }

    @Override
    protected CitizenChange newEntity() {
        return new CitizenChange();
    }

    @Override
    protected void apply(CitizenChangeDto dto, CitizenChange change) {
        change.setCitizen(reference(citizenRepository, dto.citizenId(), "Citizen"));
        change.setChangeDate(dto.changeDate());
        change.setDetails(dto.details());
    }

    @Override
    protected Specification<CitizenChange> filter(Filters<CitizenChange> filters) {
        return filters
                .equal(filters.getInt("citizenId"), root -> root.get("citizen").get("id"))
                .build();
    }
}
