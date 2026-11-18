package dae.pc.voters.service;

import dae.pc.voters.dto.AddressDto;
import dae.pc.voters.entity.Address;
import dae.pc.voters.entity.ConPostcode;
import dae.pc.voters.entity.Constituency;
import dae.pc.voters.repository.AddressRepository;
import dae.pc.voters.repository.ConPostcodeRepository;
import dae.pc.voters.repository.ConstituencyRepository;
import dae.pc.voters.repository.CountryRepository;
import dae.pc.voters.repository.PlaceRepository;
import jakarta.persistence.criteria.From;
import jakarta.persistence.criteria.Root;
import jakarta.persistence.criteria.Subquery;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;

import java.util.function.Function;

/**
 * Service for addresses. List filters: q, part of the address, postcode, the start of the postcode, placeId and
 * constituencyId.
 */
@Service
public class AddressService extends CrudService<Address, AddressDto, Integer> {

    private final PlaceRepository placeRepository;
    private final CountryRepository countryRepository;
    private final ConstituencyRepository constituencyRepository;
    private final ConPostcodeRepository conPostcodeRepository;

    @Autowired
    public AddressService(AddressRepository repository, PlaceRepository placeRepository,
                          CountryRepository countryRepository, ConstituencyRepository constituencyRepository,
                          ConPostcodeRepository conPostcodeRepository) {
        super(repository, "Address");
        this.placeRepository = placeRepository;
        this.countryRepository = countryRepository;
        this.constituencyRepository = constituencyRepository;
        this.conPostcodeRepository = conPostcodeRepository;
    }

    @Override
    protected AddressDto toDto(Address a) {
        var place = a.getPlace();
        var country = a.getCountry();
        var constituency = constituencyOf(a);
        return new AddressDto(a.getId(), a.getAddress(),
                place != null ? place.getId() : null, place != null ? place.getName() : null,
                a.getPostcode(),
                constituency != null ? constituency.getId() : null, constituency != null ? constituency.getName() : null,
                country != null ? country.getId() : null, country != null ? country.getName() : null);
    }

    @Override
    protected Address newEntity() {
        return new Address();
    }

    @Override
    protected void apply(AddressDto dto, Address a) {
        a.setAddress(dto.address());
        a.setPostcode(Filters.normalisePostcode(dto.postcode()));
        a.setPlace(reference(placeRepository, dto.placeId(), "Place"));
        a.setCountry(reference(countryRepository, dto.countryId(), "Country"));
        a.setConstituency(reference(constituencyRepository, dto.constituencyId(), "Constituency"));
    }

    @Override
    protected Specification<Address> filter(Filters<Address> filters) {
        return filters
                .add(filters.get("q"), q -> (root, query, cb) -> Filters.contains(cb, root.get("address"), q))
                .add(filters.get("postcode"), p -> (root, query, cb) ->
                        Filters.startsWith(cb, root.get("postcode"), Filters.normalisePostcode(p)))
                .equal(filters.getInt("placeId"), root -> root.get("place").get("id"))
                .add(filters.getInt("constituencyId"), id -> inConstituency(id, root -> root))
                .build();
    }

    /**
     * The address's constituency, its constituency_id or, if that is not set, as the loaders leave it, its
     * postcode's constituency, null if neither is known.
     */
    public Constituency constituencyOf(Address address) {
        if (address.getConstituency() != null) {
            return address.getConstituency();
        }
        if (address.getPostcode() == null) {
            return null;
        }
        return conPostcodeRepository.findById(address.getPostcode())
                .filter(cp -> cp.getConCode() != null)
                .flatMap(cp -> constituencyRepository.findByCode(cp.getConCode()))
                .orElse(null);
    }

    /**
     * Matches records whose address is in the constituency, by constituency_id or postcode.
     *
     * @param address the address, from the record being matched
     */
    public <X> Specification<X> inConstituency(Integer constituencyId, Function<Root<X>, From<?, Address>> address) {
        Constituency constituency = reference(constituencyRepository, constituencyId, "Constituency");
        return (root, query, cb) -> {
            From<?, Address> a = address.apply(root);
            var byId = cb.equal(a.get("constituency").get("id"), constituency.getId());
            if (constituency.getCode() == null) {
                return byId;
            }
            Subquery<String> postcodes = query.subquery(String.class);
            Root<ConPostcode> cp = postcodes.from(ConPostcode.class);
            postcodes.select(cp.get("postcode")).where(cb.equal(cp.get("conCode"), constituency.getCode()));
            return cb.or(byId, a.get("postcode").in(postcodes));
        };
    }
}
