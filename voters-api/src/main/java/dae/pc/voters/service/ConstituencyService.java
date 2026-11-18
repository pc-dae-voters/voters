package dae.pc.voters.service;

import dae.pc.voters.dto.ConstituencyDto;
import dae.pc.voters.entity.Constituency;
import dae.pc.voters.repository.ConstituencyRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Service for constituencies. List filters: q, part of the name or code, nation and region.
 */
@Service
public class ConstituencyService extends CrudService<Constituency, ConstituencyDto, Integer> {

    private final ConstituencyRepository constituencyRepository;

    @Autowired
    public ConstituencyService(ConstituencyRepository repository) {
        super(repository, "Constituency");
        this.constituencyRepository = repository;
    }

    @Override
    protected ConstituencyDto toDto(Constituency c) {
        return new ConstituencyDto(c.getId(), c.getCode(), c.getName(), c.getTla(), c.getNation(), c.getRegion(),
                c.getCtype(), c.getArea());
    }

    @Override
    protected Constituency newEntity() {
        return new Constituency();
    }

    @Override
    protected void apply(ConstituencyDto dto, Constituency c) {
        c.setCode(dto.code());
        c.setName(dto.name());
        c.setTla(dto.tla());
        c.setNation(dto.nation());
        c.setRegion(dto.region());
        c.setCtype(dto.ctype());
        c.setArea(dto.area());
    }

    @Override
    protected Specification<Constituency> filter(Filters<Constituency> filters) {
        return filters
                .add(filters.get("q"), q -> (root, query, cb) -> cb.or(
                        Filters.contains(cb, root.get("name"), q), Filters.contains(cb, root.get("code"), q)))
                .equal(filters.get("nation"), root -> root.get("nation"))
                .equal(filters.get("region"), root -> root.get("region"))
                .build();
    }

    @Transactional(readOnly = true)
    public List<String> nations() {
        return constituencyRepository.findNations();
    }

    @Transactional(readOnly = true)
    public List<String> regions() {
        return constituencyRepository.findRegions();
    }
}
