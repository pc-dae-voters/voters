package dae.pc.voters.service;

import dae.pc.voters.dto.PostcodeDto;
import dae.pc.voters.entity.ConPostcode;
import dae.pc.voters.repository.ConPostcodeRepository;
import dae.pc.voters.repository.ConstituencyRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;

/**
 * Service for the con-postcodes table, which maps postcodes to constituency codes. The postcode is the id, it is
 * normalised to upper case without spaces, so SW1A 1AA and sw1a1aa are the same postcode. List filters: q, the start
 * of the postcode, and conCode.
 */
@Service
public class PostcodeService extends CrudService<ConPostcode, PostcodeDto, String> {

    private final ConstituencyRepository constituencyRepository;

    @Autowired
    public PostcodeService(ConPostcodeRepository repository, ConstituencyRepository constituencyRepository) {
        super(repository, "Postcode");
        this.constituencyRepository = constituencyRepository;
    }

    @Override
    protected PostcodeDto toDto(ConPostcode cp) {
        var constituency = cp.getConCode() != null ? constituencyRepository.findByCode(cp.getConCode()).orElse(null) : null;
        return new PostcodeDto(cp.getPostcode(), cp.getConCode(),
                constituency != null ? constituency.getId() : null, constituency != null ? constituency.getName() : null);
    }

    @Override
    protected ConPostcode newEntity() {
        return new ConPostcode();
    }

    @Override
    protected void apply(PostcodeDto dto, ConPostcode cp) {
        if (cp.getPostcode() == null) {
            String postcode = Filters.normalisePostcode(dto.postcode());
            if (repository.existsById(postcode)) {
                throw new BadRequestException("Postcode " + postcode + " already exists");
            }
            cp.setPostcode(postcode);
        } else if (!cp.getPostcode().equals(Filters.normalisePostcode(dto.postcode()))) {
            throw new BadRequestException("The postcode can't be changed, delete it and create the new postcode");
        }
        cp.setConCode(dto.conCode());
    }

    @Override
    protected ConPostcode find(String postcode) {
        return super.find(Filters.normalisePostcode(postcode));
    }

    @Override
    protected Sort defaultSort() {
        return Sort.by("postcode");
    }

    @Override
    protected Specification<ConPostcode> filter(Filters<ConPostcode> filters) {
        return filters
                .add(filters.get("q"), q -> (root, query, cb) ->
                        Filters.startsWith(cb, root.get("postcode"), Filters.normalisePostcode(q)))
                .equal(filters.get("conCode"), root -> root.get("conCode"))
                .build();
    }
}
