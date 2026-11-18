package dae.pc.voters.service;

import dae.pc.voters.dto.VoterDto;
import dae.pc.voters.entity.Voter;
import dae.pc.voters.repository.AddressRepository;
import dae.pc.voters.repository.CitizenRepository;
import dae.pc.voters.repository.VoterRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;

/**
 * Service for voter registrations. List filters: q, words in the voter's name, citizenId, addressId, postcode, the
 * start of the postcode, placeId, constituencyId and openRegister, true or false.
 */
@Service
public class VoterService extends CrudService<Voter, VoterDto, Long> {

    private final VoterRepository voterRepository;
    private final CitizenRepository citizenRepository;
    private final AddressRepository addressRepository;
    private final AddressService addressService;

    @Autowired
    public VoterService(VoterRepository repository, CitizenRepository citizenRepository,
                        AddressRepository addressRepository, AddressService addressService) {
        super(repository, "Voter");
        this.voterRepository = repository;
        this.citizenRepository = citizenRepository;
        this.addressRepository = addressRepository;
        this.addressService = addressService;
    }

    @Override
    protected VoterDto toDto(Voter v) {
        var citizen = v.getCitizen();
        var address = v.getAddress();
        var place = address != null ? address.getPlace() : null;
        var constituency = address != null ? addressService.constituencyOf(address) : null;
        return new VoterDto(v.getId(),
                citizen != null ? citizen.getId() : null, Names.of(citizen),
                address != null ? address.getId() : null,
                address != null ? address.getAddress() : null,
                address != null ? address.getPostcode() : null,
                place != null ? place.getName() : null,
                constituency != null ? constituency.getId() : null,
                constituency != null ? constituency.getName() : null,
                v.getOpenRegister(), v.getRegistrationDate());
    }

    @Override
    protected Voter newEntity() {
        return new Voter();
    }

    @Override
    protected void apply(VoterDto dto, Voter v) {
        var citizen = reference(citizenRepository, dto.citizenId(), "Citizen");
        voterRepository.findByCitizenId(citizen.getId())
                .filter(other -> !other.getId().equals(v.getId()))
                .ifPresent(other -> {
                    throw new BadRequestException("Citizen " + citizen.getId() + " is already registered, voter " + other.getId());
                });
        v.setCitizen(citizen);
        v.setAddress(reference(addressRepository, dto.addressId(), "Address"));
        v.setOpenRegister(dto.openRegister() != null ? dto.openRegister() : Boolean.FALSE);
        v.setRegistrationDate(dto.registrationDate() != null ? dto.registrationDate() : LocalDate.now());
    }

    @Override
    protected Specification<Voter> filter(Filters<Voter> filters) {
        return filters
                .add(filters.get("q"), q -> Names.matching(q, root -> root.join("citizen")))
                .equal(filters.getInt("citizenId"), root -> root.get("citizen").get("id"))
                .equal(filters.getInt("addressId"), root -> root.get("address").get("id"))
                .add(filters.get("postcode"), p -> (root, query, cb) ->
                        Filters.startsWith(cb, root.get("address").get("postcode"), Filters.normalisePostcode(p)))
                .equal(filters.getInt("placeId"), root -> root.get("address").get("place").get("id"))
                .add(filters.getInt("constituencyId"), id -> addressService.inConstituency(id, root -> root.join("address")))
                .equal(filters.getBoolean("openRegister"), root -> root.get("openRegister"))
                .build();
    }

    @Transactional(readOnly = true)
    public VoterDto getByCitizen(Integer citizenId) {
        return voterRepository.findByCitizenId(citizenId).map(this::toDto)
                .orElseThrow(() -> new NotFoundException("Voter for citizen", citizenId));
    }

    public VoterDto setOpenRegister(Long id, boolean openRegister) {
        Voter voter = find(id);
        voter.setOpenRegister(openRegister);
        return toDto(repository.saveAndFlush(voter));
    }
}
