package dae.pc.voters.service;

import dae.pc.voters.dto.CitizenDto;
import dae.pc.voters.entity.Birth;
import dae.pc.voters.entity.Citizen;
import dae.pc.voters.entity.Voter;
import dae.pc.voters.repository.BirthRepository;
import dae.pc.voters.repository.CitizenRepository;
import dae.pc.voters.repository.CitizenStatusRepository;
import dae.pc.voters.repository.VoterRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;

import java.time.LocalDate;

/**
 * Service for citizens. List filters: q, words in the name, firstName, surname, gender, statusCode and alive, true or
 * false.
 */
@Service
public class CitizenService extends CrudService<Citizen, CitizenDto, Integer> {

    private final CitizenStatusRepository statusRepository;
    private final BirthRepository birthRepository;
    private final VoterRepository voterRepository;
    private final Names names;

    @Autowired
    public CitizenService(CitizenRepository repository, CitizenStatusRepository statusRepository,
                          BirthRepository birthRepository, VoterRepository voterRepository, Names names) {
        super(repository, "Citizen");
        this.statusRepository = statusRepository;
        this.birthRepository = birthRepository;
        this.voterRepository = voterRepository;
        this.names = names;
    }

    @Override
    protected CitizenDto toDto(Citizen c) {
        var status = c.getStatus();
        var first = c.getFirstName();
        var last = c.getSurname();
        LocalDate birthDate = c.getId() == null ? null
                : birthRepository.findFirstByCitizenId(c.getId()).map(Birth::getDate).orElse(null);
        Long voterId = c.getId() == null ? null
                : voterRepository.findByCitizenId(c.getId()).map(Voter::getId).orElse(null);
        return new CitizenDto(c.getId(),
                status != null ? status.getId() : null,
                status != null ? status.getCode() : null,
                status != null ? status.getDescription() : null,
                first != null ? first.getId() : null, first != null ? first.getName() : null,
                last != null ? last.getId() : null, last != null ? last.getName() : null,
                c.getGender(), c.getDied(), birthDate, voterId);
    }

    @Override
    protected Citizen newEntity() {
        return new Citizen();
    }

    @Override
    protected void apply(CitizenDto dto, Citizen c) {
        if (dto.statusCode() != null && !dto.statusCode().isBlank()) {
            c.setStatus(statusRepository.findByCodeIgnoreCase(dto.statusCode().trim())
                    .orElseThrow(() -> new BadRequestException("Citizen status " + dto.statusCode() + " does not exist")));
        } else {
            c.setStatus(reference(statusRepository, dto.statusId(), "Citizen status"));
        }
        c.setFirstName(names.firstName(dto.firstNameId(), dto.firstName(), dto.gender()));
        c.setSurname(names.surname(dto.surnameId(), dto.surname()));
        c.setGender(dto.gender());
        c.setDied(dto.died());
    }

    @Override
    protected Specification<Citizen> filter(Filters<Citizen> filters) {
        return filters
                .add(filters.get("q"), q -> Names.matching(q, root -> root))
                .add(filters.get("firstName"), n -> (root, query, cb) ->
                        cb.equal(cb.lower(root.get("firstName").get("name")), n.toLowerCase()))
                .add(filters.get("surname"), n -> (root, query, cb) ->
                        cb.equal(cb.lower(root.get("surname").get("name")), n.toLowerCase()))
                .equal(filters.get("gender"), root -> root.get("gender"))
                .add(filters.get("statusCode"), s -> (root, query, cb) ->
                        cb.equal(cb.lower(root.get("status").get("code")), s.toLowerCase()))
                .add(filters.getBoolean("alive"), alive -> (root, query, cb) ->
                        alive ? cb.isNull(root.get("died")) : cb.isNotNull(root.get("died")))
                .build();
    }

    /**
     * Records the citizen's death.
     */
    public CitizenDto markAsDeceased(Integer id, LocalDate date) {
        Citizen citizen = find(id);
        citizen.setDied(date);
        return toDto(repository.saveAndFlush(citizen));
    }
}
