package dae.pc.voters.service;

import dae.pc.voters.dto.PlaceDto;
import dae.pc.voters.entity.Place;
import dae.pc.voters.repository.CountryRepository;
import dae.pc.voters.repository.PlaceRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;

/**
 * Service for places. List filters: q, part of the name, and countryId.
 */
@Service
public class PlaceService extends CrudService<Place, PlaceDto, Integer> {

    private final CountryRepository countryRepository;

    @Autowired
    public PlaceService(PlaceRepository repository, CountryRepository countryRepository) {
        super(repository, "Place");
        this.countryRepository = countryRepository;
    }

    @Override
    protected PlaceDto toDto(Place place) {
        var country = place.getCountry();
        return new PlaceDto(place.getId(), place.getName(),
                country != null ? country.getId() : null, country != null ? country.getName() : null);
    }

    @Override
    protected Place newEntity() {
        return new Place();
    }

    @Override
    protected void apply(PlaceDto dto, Place place) {
        place.setName(dto.name());
        place.setCountry(reference(countryRepository, dto.countryId(), "Country"));
    }

    @Override
    protected Specification<Place> filter(Filters<Place> filters) {
        return filters
                .add(filters.get("q"), q -> (root, query, cb) -> Filters.contains(cb, root.get("name"), q))
                .equal(filters.getInt("countryId"), root -> root.get("country").get("id"))
                .build();
    }
}
