package dae.pc.voters.service;

import dae.pc.voters.dto.SurnameDto;
import dae.pc.voters.entity.Surname;
import dae.pc.voters.repository.SurnameRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;

/**
 * Service for surnames. List filters: q, part of the name.
 */
@Service
public class SurnameService extends CrudService<Surname, SurnameDto, Integer> {

    @Autowired
    public SurnameService(SurnameRepository repository) {
        super(repository, "Surname");
    }

    @Override
    protected SurnameDto toDto(Surname name) {
        return new SurnameDto(name.getId(), name.getName());
    }

    @Override
    protected Surname newEntity() {
        return new Surname();
    }

    @Override
    protected void apply(SurnameDto dto, Surname name) {
        name.setName(dto.name());
    }

    @Override
    protected Specification<Surname> filter(Filters<Surname> filters) {
        return filters
                .add(filters.get("q"), q -> (root, query, cb) -> Filters.contains(cb, root.get("name"), q))
                .build();
    }
}
