package dae.pc.voters.service;

import dae.pc.voters.dto.CitizenStatusDto;
import dae.pc.voters.entity.CitizenStatus;
import dae.pc.voters.repository.CitizenStatusRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

/**
 * Service for citizenship statuses.
 */
@Service
public class CitizenStatusService extends CrudService<CitizenStatus, CitizenStatusDto, Integer> {

    @Autowired
    public CitizenStatusService(CitizenStatusRepository repository) {
        super(repository, "Citizen status");
    }

    @Override
    protected CitizenStatusDto toDto(CitizenStatus status) {
        return new CitizenStatusDto(status.getId(), status.getCode(), status.getDescription());
    }

    @Override
    protected CitizenStatus newEntity() {
        return new CitizenStatus();
    }

    @Override
    protected void apply(CitizenStatusDto dto, CitizenStatus status) {
        status.setCode(dto.code());
        status.setDescription(dto.description());
    }
}
