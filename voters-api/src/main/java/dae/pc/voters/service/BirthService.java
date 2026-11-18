package dae.pc.voters.service;

import dae.pc.voters.dto.BirthDto;
import dae.pc.voters.entity.Birth;
import dae.pc.voters.repository.BirthRepository;
import dae.pc.voters.repository.CitizenRepository;
import dae.pc.voters.repository.PlaceRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;

/**
 * Service for birth records. List filters: citizenId, fatherId, motherId, parentId, either parent, and placeId.
 */
@Service
public class BirthService extends CrudService<Birth, BirthDto, Integer> {

    private final CitizenRepository citizenRepository;
    private final PlaceRepository placeRepository;
    private final Names names;

    @Autowired
    public BirthService(BirthRepository repository, CitizenRepository citizenRepository,
                        PlaceRepository placeRepository, Names names) {
        super(repository, "Birth");
        this.citizenRepository = citizenRepository;
        this.placeRepository = placeRepository;
        this.names = names;
    }

    @Override
    protected BirthDto toDto(Birth b) {
        var citizen = b.getCitizen();
        var first = b.getFirstName();
        var last = b.getSurname();
        var place = b.getPlace();
        var father = b.getFather();
        var mother = b.getMother();
        return new BirthDto(b.getId(),
                citizen != null ? citizen.getId() : null, Names.of(citizen),
                b.getDate(),
                first != null ? first.getId() : null, first != null ? first.getName() : null,
                last != null ? last.getId() : null, last != null ? last.getName() : null,
                b.getGender(),
                place != null ? place.getId() : null, place != null ? place.getName() : null,
                father != null ? father.getId() : null, Names.of(father),
                mother != null ? mother.getId() : null, Names.of(mother));
    }

    @Override
    protected Birth newEntity() {
        return new Birth();
    }

    @Override
    protected void apply(BirthDto dto, Birth b) {
        b.setCitizen(reference(citizenRepository, dto.citizenId(), "Citizen"));
        b.setDate(dto.date());
        b.setFirstName(names.firstName(dto.firstNameId(), dto.firstName(), dto.gender()));
        b.setSurname(names.surname(dto.surnameId(), dto.surname()));
        b.setGender(dto.gender());
        b.setPlace(reference(placeRepository, dto.placeId(), "Place"));
        b.setFather(reference(citizenRepository, dto.fatherId(), "Father"));
        b.setMother(reference(citizenRepository, dto.motherId(), "Mother"));
    }

    @Override
    protected Specification<Birth> filter(Filters<Birth> filters) {
        return filters
                .equal(filters.getInt("citizenId"), root -> root.get("citizen").get("id"))
                .equal(filters.getInt("fatherId"), root -> root.get("father").get("id"))
                .equal(filters.getInt("motherId"), root -> root.get("mother").get("id"))
                .add(filters.getInt("parentId"), id -> (root, query, cb) -> cb.or(
                        cb.equal(root.get("father").get("id"), id), cb.equal(root.get("mother").get("id"), id)))
                .equal(filters.getInt("placeId"), root -> root.get("place").get("id"))
                .build();
    }
}
