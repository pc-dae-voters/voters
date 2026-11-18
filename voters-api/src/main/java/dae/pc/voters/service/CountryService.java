package dae.pc.voters.service;

import dae.pc.voters.dto.CountryDto;
import dae.pc.voters.entity.Country;
import dae.pc.voters.repository.CountryRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;

/**
 * Service for countries. List filters: q, part of the name.
 */
@Service
public class CountryService extends CrudService<Country, CountryDto, Integer> {

    @Autowired
    public CountryService(CountryRepository repository) {
        super(repository, "Country");
    }

    @Override
    protected CountryDto toDto(Country country) {
        return new CountryDto(country.getId(), country.getName());
    }

    @Override
    protected Country newEntity() {
        return new Country();
    }

    @Override
    protected void apply(CountryDto dto, Country country) {
        country.setName(dto.name());
    }

    @Override
    protected Specification<Country> filter(Filters<Country> filters) {
        return filters
                .add(filters.get("q"), q -> (root, query, cb) -> Filters.contains(cb, root.get("name"), q))
                .build();
    }
}
