package dae.pc.voters.service;

import dae.pc.voters.dto.FirstNameDto;
import dae.pc.voters.entity.FirstName;
import dae.pc.voters.repository.FirstNameRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;

/**
 * Service for first names. List filters: q, part of the name, and gender.
 */
@Service
public class FirstNameService extends CrudService<FirstName, FirstNameDto, Integer> {

    @Autowired
    public FirstNameService(FirstNameRepository repository) {
        super(repository, "First name");
    }

    @Override
    protected FirstNameDto toDto(FirstName name) {
        return new FirstNameDto(name.getId(), name.getName(), name.getGender());
    }

    @Override
    protected FirstName newEntity() {
        return new FirstName();
    }

    @Override
    protected void apply(FirstNameDto dto, FirstName name) {
        name.setName(dto.name());
        name.setGender(dto.gender());
    }

    @Override
    protected Specification<FirstName> filter(Filters<FirstName> filters) {
        return filters
                .add(filters.get("q"), q -> (root, query, cb) -> Filters.contains(cb, root.get("name"), q))
                .equal(filters.get("gender"), root -> root.get("gender"))
                .build();
    }
}
